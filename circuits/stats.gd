class_name Stats
extends Object

var _roads_count: int = 0
var _laps_count: int = 0
var _penalty: float

# current road index
var _road_idx: int = 0

# next road index
var _next_road_idx: int = 1

# current lap index
var _lap_idx: int = 0 setget ,lap_idx

# lap elapsed_times in seconds
var _laps: Array = []

# lap penalties in seconds
var _penalties: Array = []


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
	if self._road_idx == 0:
		self._lap_idx += 1


func lap_idx() -> int:
	return _lap_idx


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
