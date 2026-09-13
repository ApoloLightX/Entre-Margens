extends RefCounted
const DAY_NAMES = ["Calha", "Pedra", "Fio", "Ofício", "Cais", "Mesa"]
var state

func _init(s) -> void:
	state = s

func advance(seconds: float) -> bool:
	# Six-minute prototype day; full game setting belongs to later iteration.
	state.data.minute = minf(float(state.data.minute)+seconds*3.0, 1440.0)
	return float(state.data.minute) >= 1440.0

func new_day() -> void:
	state.data.absolute_day += 1
	state.data.minute = 360.0
	state.data.energy = 100
	state.data.foraged.clear()
	state.data.stock_bought.clear()
	state.data.fished = 0

func label() -> String:
	var d = int(state.data.absolute_day)
	var minute = int(state.data.minute)
	return "%s %02d • Fresta • %02d:%02d" % [DAY_NAMES[(d-1)%6], ((d-1)%24)+1, mini(minute/60, 23), minute%60]
