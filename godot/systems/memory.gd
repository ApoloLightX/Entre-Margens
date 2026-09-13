extends RefCounted
## Evidence survives changes in displayed world. No economy rollback.
var state
var inventory

func _init(s, i) -> void:
	state = s
	inventory = i

func record(id: String, value: String, source: String) -> String:
	if not state.data.evidence.has(id):
		state.data.evidence[id] = {"value":value,"source":source,"day":int(state.data.absolute_day)}
	return "Registrado: " + state.data.evidence[id].value

func sign() -> String:
	if state.data.anomaly:
		record("sign_after", "A placa agora diz Calha 8.", "Observação no cais")
		if state.data.evidence.has("sign_before") and not state.data.evidence.sign_before.get("distorted",false): return "Seu registro diz CALHA 3. A placa agora diz CALHA 8. Isso merece uma segunda fonte."
		return "A placa diz CALHA 8. A fixação parece mais antiga que a tinta. Procure uma leitura isolada na galeria."
	return record("sign_before", "A placa do cais diz Calha 3.", "Observação no cais")

func survey() -> String:
	record("survey", "O regulador isolado identifica esta saída como Calha 3.", "Medição independente na galeria")
	if not state.data.anomaly: return "Leitura registrada. A etiqueta técnica indica Calha 3. Não há alteração confirmada."
	return "A saída mede como Calha 3, mas o cais mostra Calha 8. Duas fontes podem fundamentar uma âncora."

func anchor(id: String) -> String:
	if id in state.data.anchors: return "Esta prova já está protegida."
	if not state.data.evidence.has(id): return "Registre primeiro a evidência."
	if state.data.evidence[id].get("distorted",false): return "Este registro foi alterado. Proteja uma nova medição independente."
	if state.data.anchors.size() >= 3: return "Os três vínculos do estojo estão ocupados."
	if inventory.count("seal") < 1: return "Faça um estojo na bancada: 2 fibras e 1 quartzo."
	state.data.anchors.append(id)
	return "Âncora protegida: " + state.data.evidence[id].value

func enough_evidence() -> bool:
	return state.data.evidence.has("sign_after") and (state.data.evidence.has("survey") or state.data.evidence.has("tag"))

func resolve(mode: String) -> String:
	if mode not in ["isolate", "observe"]: return "Escolha desconhecida."
	if state.data.ending != "": return "A decisão já foi registrada. A vila continua disponível."
	if not state.data.anomaly or not enough_evidence(): return "Compare a placa atual com a medição ou a etiqueta pescada antes de decidir."
	if state.data.anchors.is_empty(): return "Proteja pelo menos uma prova no Diário antes de calibrar. O estojo exige 2 fibras e 1 quartzo."
	state.data.ending = mode
	return "RETORNO ISOLADO. O cais fica estável; a pesquisa continuará com menor circulação." if mode == "isolate" else "MEDIÇÃO MANTIDA. A vila conserva o fluxo; os moradores terão de verificar as referências juntos."

func overnight() -> String:
	if int(state.data.absolute_day) == 4 and not state.data.anomaly:
		state.data.anomaly = true
		if state.data.evidence.has("sign_before") and "sign_before" not in state.data.anchors:
			state.data.evidence.sign_before.value="A tinta se recompôs: Calha 8. A referência anterior está ilegível."
			state.data.evidence.sign_before["distorted"]=true
		return "O vento voltou. No cais, algo parece ter mudado."
	return "A neve guarda marcas de ontem. Um novo dia começa."
