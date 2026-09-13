extends RefCounted
## Pure serializable domain state. Absolute identity never uses display names.
var data: Dictionary

func _init() -> void:
	reset()

func reset() -> void:
	data = {
		"schema_version": 1, "content_version": "0.2-action", "name": "Viajante", "pronouns": "elu", "origin": "Costa", "hair": 0, "color": 0,
		"absolute_day": 1, "minute": 360.0, "money": 40, "energy": 100, "zone": "village", "position": [350.0, 470.0],
		"seed": 48151, "inventory": {"spore":4, "root_seed":2, "moss":4}, "plots": {},
		"heat": false, "repaired": false, "selected_crop": "lantern", "relationships": {}, "talked": {}, "answered": {},
		"foraged": {}, "fished": 0, "stock_bought": {}, "claims": [], "flags": {},
		"evidence": {}, "anchors": [], "anomaly": false, "ending": "", "started": false,
		"health":100, "focus":100.0, "last_attack":-99.0, "last_cast":-99.0, "combat_flash":0.0, "ability":"cordao", "defeated":[]
	}
