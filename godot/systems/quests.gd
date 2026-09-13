extends RefCounted
var state
var catalog
var inventory

func _init(s, c, i) -> void:
	state = s
	catalog = c
	inventory = i

func claim(id: String) -> String:
	if id in state.data.claims: return "Esta entrega já foi registrada."
	if id == "calha" and not state.data.repaired: return "Repare a calha antes de pedir o pagamento."
	if id == "memory" and state.data.ending == "": return "Ainda falta decidir o que fazer com o regulador."
	if id == "soup" and not inventory.exchange(catalog.tables.quests.soup.cost, {}): return "Prepare um caldo na bancada de casa: 1 peixe e 1 fungo."
	state.data.claims.append(id)
	state.data.money += int(catalog.tables.quests[id].money)
	return "Contrato concluído: +%d fichas." % int(catalog.tables.quests[id].money)
