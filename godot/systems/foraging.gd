extends RefCounted
var state
var inventory
var memory
var catalog

func _init(s, i, m, c) -> void:
	state=s
	inventory=i
	memory=m
	catalog=c

func gather(id: String, item: String, amount: int) -> String:
	if state.data.foraged.has(id): return "Já coletado hoje. Deixe a margem descansar."
	if not inventory.exchange({}, {item:amount}): return "Mochila cheia."
	state.data.foraged[id]=true
	return "Coletou %d × %s." % [amount,catalog.item_name(item)]

func fish(success: bool, cave: bool) -> String:
	if int(state.data.fished)>=6: return "Você já fez seis capturas hoje. Volte amanhã ou explore outra atividade."
	if not success: return "A linha afrouxou. O peixe seguiu. Nenhum equipamento foi perdido."
	var id = "silverfish" if cave else "fish"
	if not inventory.exchange({}, {id:1}): return "Mochila cheia."
	state.data.fished += 1
	state.data.minute = minf(float(state.data.minute)+15, 1439)
	if int(state.data.absolute_day)>=2 and not state.data.evidence.has("tag"):
		inventory.exchange({}, {"tag":1})
		memory.record("tag","Etiqueta pescada: Calha 3, revisão antiga.","Objeto retirado da água")
		return "Pegou um peixe e uma etiqueta presa à linha: Calha 3. A prova foi guardada no Diário."
	return "Pescou %s. A água volta a ficar quieta." % catalog.item_name(id)
