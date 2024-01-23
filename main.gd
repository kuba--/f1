class_name Main
extends Control

const Stun = preload("res://p2p/stun.gd")
export(String) var StunIP = "69.164.203.66"
export(int) var StunPort = 443
var stun: Stun
var peer := WebRTCPeerConnection.new()
var channel: WebRTCDataChannel  = null

onready var race_car_buttons = [
	$Container/CarContainer/GreenButton,
	$Container/CarContainer/OrangeButton,
	$Container/CarContainer/RedButton,
	$Container/CarContainer/WhiteButton
]
var selected_race_car_idx = null

onready var circuit_buttons = [
	$Container/CircuitContainer/ChinaButton,
	$Container/CircuitContainer/PolandButton,
	$Container/CircuitContainer/MexicoButton,
	$Container/CircuitContainer/BahrainButton
]
var selected_cicruit_idx = null

onready var mode_buttons = [
	$Container/ModeContainer/TimeButton,
	$Container/ModeContainer/RacingButton,
	$Container/ModeContainer/MultiplayerButton
]
var selected_mode_idx = null

onready var root := get_tree()
var loaded_curcuit_scene: PackedScene = null


func _ready():
	randomize()
	peer.initialize({
		"iceServers": [
			{ "urls": ["stun:stun.l.google.com:19302"] },
#			{
#				"urls": [ "turn:turn.anyfirewall.com:443?transport=tcp" ], # One or more TURN servers.
#				"username": "webrtc", # Optional username for the TURN server.
#				"credential": "webrtc", # Optional password for the TURN server.
#			}
		]
	})
	channel = peer.create_data_channel("f1", {"negotiated": true, "id": 0xF1})
	peer.connect("ice_candidate_created", self, "_on_ice_candidate")

	Global.race_car_registry.clear()
	$SettingsPanel/HBoxContainer/Label.text = Global.my_unique_id.substr(0, 3)

	$Container/CarContainer/GreenButton.init(Global.ICON_RACE_CAR_GREEN)
	$Container/CarContainer/OrangeButton.init(Global.ICON_RACE_CAR_ORANGE)
	$Container/CarContainer/RedButton.init(Global.ICON_RACE_CAR_RED)
	$Container/CarContainer/WhiteButton.init(Global.ICON_RACE_CAR_WHITE)

	$Container/CircuitContainer/ChinaButton.init(Global.ICON_CHINA)
	$Container/CircuitContainer/PolandButton.init(Global.ICON_POLAND)
	$Container/CircuitContainer/MexicoButton.init(Global.ICON_MEXICO)
	$Container/CircuitContainer/BahrainButton.init(Global.ICON_BAHRAIN)

	$Container/ModeContainer/TimeButton.init(Global.ICON_MODE_TIME)
	$Container/ModeContainer/RacingButton.init(Global.ICON_MODE_RACING)
	$Container/ModeContainer/MultiplayerButton.init(Global.ICON_MODE_MULTIPLAYER, false)


func _process(_delta: float):
	if stun and stun.is_connected_to_host():
		stun.poll_once()
	if peer:
		peer.poll()
	if client:
		client.poll()
		if client.get_available_packet_count() > 0:
			var data: PoolByteArray = client.get_packet()
			if not data.empty():
				$TextEdit.text = data.get_string_from_utf8()
	if server:
		server.poll()
		if server.get_available_packet_count() > 0:
			var data: PoolByteArray = server.get_packet()
			if not data.empty():
				$TextEdit.text = data.get_string_from_utf8()


func _exit_tree():
	print_debug("EXIT TREE")
	if client:
		client.close_connection()
		client = null

	if server:
		server.close_connection()
		server = null

	if peer:
		peer.close()
	if channel:
		channel.close()

func _on_race_car_button_pressed(selected: bool, idx: int):
	if selected:
		if self.selected_race_car_idx != null:
			self.race_car_buttons[self.selected_race_car_idx].reset()
		self.selected_race_car_idx = idx
	elif idx == self.selected_race_car_idx:
		self.selected_race_car_idx = null
	_try_load_circuit()


func _set_race_car_buttons_disabled():
	for btn in self.race_car_buttons:
		btn.set_disabled(true)


func _on_circuit_button_pressed(selected: bool, idx: int):
	if selected:
		if self.selected_cicruit_idx != null:
			self.circuit_buttons[self.selected_cicruit_idx].reset()
		self.selected_cicruit_idx = idx
	elif idx == self.selected_cicruit_idx:
		self.selected_cicruit_idx = null
	_try_load_circuit()


func _set_circuit_buttons_disabled():
	for btn in self.circuit_buttons:
		btn.set_disabled(true)


func _on_mode_button_pressed(selected: bool, idx: int):
	if selected:
		match idx:
			Global.Mode.TIME, Global.Mode.RACING:
				_set_mode_buttons_disabled()
				Global.game_play_mode = idx
#				self.root.call_deferred("change_scene_to", curcuit_scene)
				var err := self.root.change_scene_to(self.loaded_curcuit_scene)
				assert(err == OK, "node.change_scene_to error %d" % err)
			Global.Mode.MULTIPLAYER:
				print_debug("MULTIPLAYER not implemented, yet")
#				stun = Stun.new(StunIP, StunPort)
#				var err := stun.connect("message_received", self, "_on_server_message_received")
#				assert(err == OK, "connect message_received error %d" % err)
#				stun.send_binding_request()
#				var result = yield(stun, 'message_received')


var client: NetworkedMultiplayerENet
var server: NetworkedMultiplayerENet

var local_ip: String
var remote_ip: String
var local_port: int
var remote_port: int

func _on_ice_candidate(media: String, index: int, name: String):
	var arr = name.split(" ")
	index = int(arr[0].split(':')[1])
	if index == 1:
		local_ip = arr[4]
		local_port = int(arr[5])
	elif index == 2:
		remote_ip = arr[4]
		remote_port = int(arr[5])
	$TextEdit.text = local_ip + ":" + str(local_port) + "->" + remote_ip + ":" + str(remote_port)
	print_debug(index, "\n", local_port, " ", remote_port)

func _on_server_message_received(response: Stun.Message, request: Stun.Message):
	stun.close()

	var my_addr: Stun.XorMappedAddressAttribute = response.xor_mapped_address()
	var my_ip: String = my_addr.ip
	var my_port := my_addr.port
	var pop := WindowDialog.new()
	pop.set_size(Vector2(600, 600))
	pop.connect("popup_hide", self, "_exit_tree")
	var lbl := Label.new()
	lbl.text = "REQUEST:\n" + str(request) + "\n--\n\nRESPONSE:\n" + str(response)

	server = NetworkedMultiplayerENet.new()
	get_tree().connect("network_peer_connected",    self, "_client_connected"   )
	get_tree().connect("network_peer_disconnected", self, "_client_disconnected")

	var err = server.create_server(my_port, 2)
	if err != OK:
		$TextEdit.text = "create_server error %d" % err
	else:
		$TextEdit.text = "create server OK"
	get_tree().set_network_peer(server)

	lbl.text += "\n----------------------\nIP:" + my_ip + "\nPORT:" + str(my_port) + "\n"
	pop.add_child(lbl)
	add_child(pop)
	pop.popup_centered()


func _on_connect_pressed():
	var err = peer.create_offer()
	if err != OK:
		assert(err == OK, "create_offer error %d" % err)

func _on_server_pressed():
	var pop := WindowDialog.new()
	pop.set_size(Vector2(600, 600))
	pop.connect("popup_hide", self, "_exit_tree")
	var lbl := Label.new()
	lbl.text = "\n" + local_ip + ":" + str(local_port) + "->" + remote_ip + ":" + str(remote_port)

	peer.close()
	server = NetworkedMultiplayerENet.new()
	server.server_relay = true
	get_tree().connect("network_peer_connected",    self, "_client_connected"   )
	get_tree().connect("network_peer_disconnected", self, "_client_disconnected")
	var err = server.create_server(local_port, 2)
	if err != OK:
		lbl.text += "\ncreate_server error %d" % err
	else:
		lbl.text += "\ncreate server OK"
	get_tree().set_network_peer(server)

	pop.add_child(lbl)
	add_child(pop)
	pop.popup_centered()

func _on_join_pressed():
	client = NetworkedMultiplayerENet.new()
	var srv_addr :Array = $TextEdit.text.split(':')
	var srv_ip: String = srv_addr[0]
	var srv_port := int(srv_addr[1])
	print_debug(srv_ip, ":", srv_port)

	peer.close()
	var err = client.create_client(srv_ip, srv_port, 0, 0, local_port)
	if err != OK:
		$TextEdit.text = "create_client error %d" % err
	else:
		$TextEdit.text = "create client OK"
		get_tree().set_network_peer(client)
		client.put_packet("Client - Ala ma kota".to_utf8())

#	stun = Stun.new(StunIP, StunPort)
#	var err := stun.connect("message_received", self, "_on_client_message_received")
#	assert(err == OK, "connect message_received error %d" % err)
#	stun.send_binding_request()



func _on_client_message_received(response: Stun.Message, request: Stun.Message):
	stun.close()

	var srv_addr: Array = $TextEdit.text.split(':')
	var srv_ip: String = srv_addr[0]
	var srv_port := int(srv_addr[1])

	var my_addr: Stun.MappedAddressAttribute = response.mapped_address()
	$SettingsPanel/HBoxContainer/Label.text = "'" + my_addr.ip + "' '" + str(my_addr.port) + "'"

	var err = client.create_client(srv_ip, srv_port, 0, 0, my_addr.port)
	if err != OK:
		$TextEdit.text = "create_client error %d" % err
	else:
		$TextEdit.text = "create client OK"
	get_tree().set_network_peer(client)





func _client_connected(id):
	$TextEdit.text = "_client_connected " +  str(id)

func _client_disconnected(id):
	$TextEdit.text = "_client_disconnected " +  str(id)


func _set_mode_buttons_disabled():
	for btn in self.mode_buttons:
		btn.set_disabled(true)


func _set_mode_buttons_visible():
	$Container/CarContainer.visible = false
	$Container/CircuitContainer.visible = false
	$Container/ModeContainer.visible = true


func _try_load_circuit():
	if self.selected_race_car_idx == null or self.selected_cicruit_idx == null:
		return
	Global.my_race_car_idx = selected_race_car_idx
	var circuit = Global.CIRCUITS[selected_cicruit_idx]
	if circuit == null:
		return
	self.loaded_curcuit_scene = _load_circuit()
	assert(self.loaded_curcuit_scene != null, "circuit scene is not loaded")
	_set_mode_buttons_visible()


func _load_circuit() -> PackedScene:
	var scene: PackedScene = Global.CIRCUITS_CACHE[selected_cicruit_idx] as PackedScene
	if scene != null:
		return scene
	_set_race_car_buttons_disabled()
	_set_circuit_buttons_disabled()

	var loader := ResourceLoader.load_interactive(Global.CIRCUITS[self.selected_cicruit_idx], "PackedScene")
	self.circuit_buttons[self.selected_cicruit_idx].set_max(loader.get_stage_count())
	while scene == null:
		var err := loader.poll()
		if err == ERR_FILE_EOF:
			self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage_count())
			scene = loader.get_resource() as PackedScene
			Global.CIRCUITS_CACHE[self.selected_cicruit_idx] = scene
		assert(err == OK || err == ERR_FILE_EOF, "loader.poll error %d" % err)
		self.circuit_buttons[self.selected_cicruit_idx].set_progress(loader.get_stage())
	return scene

