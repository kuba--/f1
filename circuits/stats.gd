class_name Stats
extends Object

var _roads_count: int = 0
var _laps_count: int = 0
var _penalty: float

# current road index
var _road_idx: int = 0 setget ,current_road_idx

# next road index
var _next_road_idx: int = 1

# current lap index
var _lap_idx: int = 0 setget ,lap_idx

# lap elapsed_times in seconds
var _laps: Array = []

# lap penalties in seconds
var _penalties: Array = []

var _road_avg: float
var _road_avg_max: float = 0.0
var _road_avg_n: int = 0

func _init(roads_count: int, laps_count: int, penalty: float):
	self._roads_count = roads_count
	self._laps_count = laps_count
	self._penalty = penalty
	self._laps.resize(1 + laps_count)
	self._laps.fill(0.0)
	self._penalties.resize(1 + laps_count)
	self._penalties.fill(0.0)


func set_time_elapsed(road_idx: int, time_elapsed: float):
	if self._lap_idx > self._laps_count or road_idx == self._road_idx:
		return
	if road_idx < self._next_road_idx:
		if road_idx == 0:
			for _i in range(self._next_road_idx, self._roads_count):
				self._penalties[self._lap_idx] += self._penalty
	elif road_idx > self._next_road_idx:
		for _i in range(self._next_road_idx, road_idx):
			self._penalties[self._lap_idx] += self._penalty

	self._road_idx = road_idx
	self._next_road_idx = wrapi(road_idx + 1, 0, self._roads_count)
	self._laps[self._lap_idx] = time_elapsed
	self._road_avg_n += 1
	self._road_avg = time_elapsed / self._road_avg_n
	if self._road_avg_max < self._road_avg:
		self._road_avg_max = self._road_avg
	if self._road_idx == 0:
		self._lap_idx += 1

func current_road_idx() -> int:
	return _road_idx

func lap_idx() -> int:
	return _lap_idx

func finished() -> bool:
	return (self._lap_idx >= self._laps_count)

func lap(idx: int) -> Array:
	assert(idx >= 0, "index out of range")
	var t: float = self._laps[idx] if idx == 0 else self._laps[idx] - self._laps[idx-1]
	return [
		t,
		self._penalties[idx],
		t + self._penalties[idx]
	]


func total() -> Array:
	var t: Array = [0.0, 0.0, 0.0]
	var n: int = self._lap_idx if self._lap_idx < self._laps_count else self._laps_count
	for i in range(0, n):
		var ti := lap(i)
		t[0] += ti[0]
		t[1] += ti[1]
		t[2] += ti[2]
	return t

func approx_total() -> Array:
	var t: Array = [0.0, 0.0, 0.0]
	for i in range(0, self._laps_count):
		if self._laps[i] > 0.0:
			t[0] = self._laps[i]
		t[1] += self._penalties[i]

	# print_debug("\nlaps:", _laps, "\tt:", t)
	if self._lap_idx < self._laps_count:
		var n: int = self._roads_count - self._road_idx
		t[0] += n * self._road_avg_max
		n = self._laps_count - self._lap_idx - 1
		if n > 0:
			t[0] += n * self._roads_count * self._road_avg_max
	t[2] = t[0] + t[1]
	# print_debug("\tavg:", _road_avg_max, "\tt:", t)
	return t
