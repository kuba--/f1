package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"log/slog"
	"maps"
	"net"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

const (
	DefaultPort            = 35053
	MaxMessageSize         = 256
	MessageChannelCapacity = 64
	SessionTTL             = 5 * time.Minute
)

// udp datagram
type Message struct {
	buf  *bytes.Buffer
	n    int
	addr *net.UDPAddr
}

// request/response payload
type Payload struct {
	Type   string            `json:"type"`            // rs: register session, rp: register peer
	ID     string            `json:"id"`              // session id
	Size   int               `json:"size,omitempty"`  // session size
	Name   string            `json:"name,omitempty"`  // peer's name
	Addr   string            `json:"addr,omitempty"`  // response address (host:port)
	Peers  map[string]string `json:"peers,omitempty"` // peers: name => address (host:port)
	Secret string            `json:"secret,omitempty"`
	Error  string            `json:"error,omitempty"` // error string
}

type Session struct {
	capacity  int
	peers     map[string]*net.UDPAddr
	timestamp time.Time
}

func NewSession(capacity int) *Session {
	return &Session{
		capacity:  capacity,
		peers:     make(map[string]*net.UDPAddr, capacity),
		timestamp: time.Now().UTC(),
	}
}

func (s *Session) AddPeer(name string, addr *net.UDPAddr) error {
	if _, exists := s.peers[name]; exists {
		return errors.New("peer already exists")
	}

	if s.IsFull() {
		return errors.New("session is full")
	}
	s.peers[name] = addr
	s.timestamp = time.Now().UTC()

	return nil
}

func (s *Session) Size() int {
	return len(s.peers)
}

func (s *Session) IsFull() bool {
	return s.capacity <= len(s.peers)
}

var (
	bufPool = sync.Pool{
		New: func() interface{} {
			return bytes.NewBuffer(make([]byte, MaxMessageSize))
		},
	}
	udpConn *net.UDPConn

	// registered sessions
	regSessions = make(map[string]*Session)
	secret      string
)

func main() {
	if secret == "" {
		secret = os.Getenv("HOLEPUNCHER_SECRET")
	}
	port := flag.Int("p", DefaultPort, "hole puncher running on UDP port")
	flag.Usage = func() {
		flag.PrintDefaults()
		os.Exit(1)
	}
	flag.Parse()

	// resolve UDP address
	if addr, err := net.ResolveUDPAddr("udp", ":"+Itoa(*port)); err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	} else {
		// start listening for UDP packages on the given address
		if udpConn, err = net.ListenUDP("udp", addr); err != nil {
			slog.Error(err.Error())
			os.Exit(1)
		}
	}

	// handle SIGINT and SIGTERM.
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	ctx, cancel := context.WithCancel(context.Background())
	defer func() {
		cancel()
		close(sigchan)
		udpConn.Close()
	}()

	go func() {
		select {
		case sig := <-sigchan:
			if sig != nil {
				slog.Info("syscall", "sig", sig)
			}
			cancel()
			udpConn.Close()
		case <-ctx.Done():
			return
		}
	}()

	// run hole puncher
	if err := run(ctx); err != nil {
		slog.Error(err.Error())
	}

	slog.Info("--- DONE ---")
}

func run(ctx context.Context) error {
	msgchan := make(chan *Message, MessageChannelCapacity)
	defer close(msgchan)
	go recvMessages(ctx, msgchan)

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()

		default:
			buf := bufPool.Get().(*bytes.Buffer)

			n, addr, err := readFromUDP(buf.Bytes())
			if err != nil {
				bufPool.Put(buf)
				slog.Error(err.Error())
				continue
			}

			msgchan <- &Message{buf, n, addr}
		}
	}
}

func recvMessages(ctx context.Context, msgchan <-chan *Message) {
	for t := time.NewTimer(SessionTTL); ; t.Reset(SessionTTL) {
		select {
		case <-ctx.Done():
			return

		case <-t.C:
			// optimal version of <-time.After(SessionTTL):
			for id, s := range regSessions {
				// cleanup sessions/leftovers
				if time.Now().UTC().Sub(s.timestamp) > SessionTTL {
					delete(regSessions, id)
				}
			}

		case msg, ok := <-msgchan:
			// get next UDP message
			if !ok {
				return
			}
			if data := bytes.TrimSpace(msg.buf.Bytes()[:msg.n]); len(data) > 0 {
				onMessage(data, msg.addr)
			}
			bufPool.Put(msg.buf)
		}
		t.Stop()
	}
}

func onMessage(data []byte, addr *net.UDPAddr) {
	var payload Payload
	if err := json.Unmarshal(data, &payload); err != nil {
		slog.Warn("onMessage", "err", err, "addr", addr.String(), "data", string(data))
		return
	}
	if secret != payload.Secret {
		slog.Warn("secret", "addr", addr.String(), "data", string(data))
		return
	}

	payload.Addr = addr.String()
	switch payload.Type {
	case "rs":
		if err := registerSession(payload.ID, payload.Size); err != nil {
			payload.Error = err.Error()
		}

	case "rp":
		if err := registerPeer(payload.ID, payload.Name, addr); err != nil {
			payload.Error = err.Error()
			break
		}

		if s := regSessions[payload.ID]; s.IsFull() {
			peers := make(map[string]string)
			for pn, pa := range s.peers {
				peers[pn] = pa.String()
			}

			// exchange peers info
			for pn, pa := range s.peers {
				payload.Name = pn
				payload.Addr = pa.String()
				payload.Peers = maps.Clone(peers)
				delete(payload.Peers, pn)
				writeToUDP(&payload, pa)
			}
			delete(regSessions, payload.ID)
		}
		return

	default:
		payload.Error = "invalid protocol"
	}

	writeToUDP(&payload, addr)
}

func registerSession(id string, size int) error {
	if id == "" {
		return errors.New("session id not found")
	}
	if _, ok := regSessions[id]; ok {
		return errors.New("session already exists")
	}
	regSessions[id] = NewSession(size)
	return nil
}

func registerPeer(id string, name string, addr *net.UDPAddr) error {
	if id == "" {
		return errors.New("session id not found")
	}
	if name == "" {
		return errors.New("peer name not found")
	}

	s, ok := regSessions[id]
	if !ok {
		return errors.New("session not found")
	}

	return s.AddPeer(name, addr)
}

func readFromUDP(b []byte) (n int, addr *net.UDPAddr, err error) {
	n, addr, err = udpConn.ReadFromUDP(b)
	if err != nil {
		return
	}
	if addr == nil {
		err = errors.New("could not read from UDP (address is nil)")
		return
	}
	if n < 1 {
		err = errors.New("no data")
		return
	}

	return
}

func writeToUDP(payload *Payload, addr *net.UDPAddr) {
	b, err := json.Marshal(payload)
	if err == nil {
		_, err = udpConn.WriteToUDP(b, addr)
	}

	if err != nil {
		slog.Error(err.Error(), "payload", payload)
	}
}
