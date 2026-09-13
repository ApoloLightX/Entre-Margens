extends RefCounted
## Immutable external content. No gameplay mutation belongs here.
var tables: Dictionary = {}

func _init() -> void:
	for table in ["items", "crops", "recipes", "shops", "quests", "npcs", "dialogues", "world"]:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % table))
		assert(parsed is Dictionary, "Invalid content table: " + table)
		tables[table] = parsed

func get_table(id: String) -> Dictionary:
	return tables[id]

func item_name(id: String) -> String:
	return tables.items.get(id, {}).get("name", id)

func validate() -> Array[String]:
	var errors: Array[String] = []
	for id in tables.crops:
		var crop: Dictionary = tables.crops[id]
		for key in ["seed", "yield_item"]:
			if not tables.items.has(crop[key]): errors.append("Crop %s references missing %s" % [id, key])
	for table in ["recipes", "quests"]:
		for id in tables[table]:
			for item in tables[table][id].get("cost", {}):
				if not tables.items.has(item): errors.append("Unknown ingredient: " + item)
	for id in tables.npcs:
		if not tables.dialogues.has(tables.npcs[id].dialogue): errors.append("Missing dialogue: " + id)
	return errors
