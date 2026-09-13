extends RefCounted
var state
var catalog
var inventory

func _init(s, c, i) -> void:
	state = s
	catalog = c
	inventory = i

func interact(id: String) -> String:
	if not state.data.plots.has(id):
		var crop_id: String = state.data.selected_crop
		var crop: Dictionary = catalog.tables.crops[crop_id]
		if not inventory.exchange({crop.seed:1}, {}): return "Faltam sementes. Neri vende na loja."
		state.data.plots[id] = {"crop":crop_id, "growth":0, "water":false}
		return "%s plantado. Use E novamente para umedecer o leito." % crop.name
	var plot: Dictionary = state.data.plots[id]
	var crop: Dictionary = catalog.tables.crops[plot.crop]
	if int(plot.growth) >= int(crop.days):
		if not inventory.exchange({}, {crop.yield_item:int(crop["yield"])}): return "Mochila cheia. Venda ou use alguns materiais."
		state.data.plots.erase(id)
		state.data.flags["harvested"] = true
		return "Colheita: %d × %s." % [crop["yield"], crop.name]
	if plot.water: return "Leito úmido. %s • %d/%d noites. %s" % [crop.name, plot.growth, crop.days, "Precisa da calha aquecida." if crop.warm else "Tolera o frio."]
	plot.water = true
	return "Leito umedecido. Cresce durante a noite se as condições forem adequadas."

func overnight() -> void:
	var warm = bool(state.data.heat) and inventory.count("moss") > 0
	if warm: inventory.exchange({"moss":1}, {})
	for id in state.data.plots:
		var plot: Dictionary = state.data.plots[id]
		var crop: Dictionary = catalog.tables.crops[plot.crop]
		if plot.water and (not crop.warm or warm): plot.growth = mini(int(plot.growth)+1, int(crop.days))
		plot.water = false
	if inventory.count("moss") == 0: state.data.heat = false

func heat_action() -> String:
	if not state.data.repaired:
		if not inventory.exchange({"fiber":3, "stone":2}, {}): return "Reparo: 3 fibras e 2 pedras. Colete nos arredores ou compre com Neri."
		state.data.repaired = true
		state.data.heat = true
		return "Calha reparada. O circuito consome 1 musgo por noite aquecida."
	if not state.data.heat and inventory.count("moss") == 0: return "Falta musgo-de-brasa. Há musgo junto às pedras e na loja."
	state.data.heat = not state.data.heat
	return "Calha aquecida: %s. Consumo: 1 musgo por noite." % ("ligada" if state.data.heat else "desligada")
