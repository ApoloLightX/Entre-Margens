extends RefCounted
var state
var catalog

func _init(s, c) -> void:
	state = s
	catalog = c

func greeting(id: String) -> String:
	if int(state.data.talked.get(id, 0)) != int(state.data.absolute_day):
		state.data.talked[id] = state.data.absolute_day
		state.data.relationships[id] = mini(int(state.data.relationships.get(id, 0))+1, 30)
	var text_key = "resolved" if state.data.ending != "" else "anomaly" if state.data.anomaly else "normal"
	return catalog.tables.dialogues[id][text_key]

func answer(id: String, index: int) -> String:
	var options: Array = catalog.tables.dialogues[id].choices
	if index < 0 or index >= options.size(): return ""
	var choice: Dictionary = options[index]
	var key = "%s:%d" % [id, int(state.data.absolute_day)]
	if not state.data.answered.has(key):
		state.data.answered[key] = true
		state.data.relationships[id] = clampi(int(state.data.relationships.get(id, 0))+int(choice.trust), 0, 30)
	return choice.response if int(choice.trust)>0 else "Tudo bem. Hoje ainda tenho meu trabalho. Podemos conversar depois."

func level(id: String) -> String:
	var value = int(state.data.relationships.get(id, 0))
	return "Confiança" if value >= 12 else "Familiaridade" if value >= 5 else "Primeiros contatos"
