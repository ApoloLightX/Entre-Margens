extends RefCounted
const DEFAULT_PATH = "user://entre_margens.json"
var last_error = ""

func validate(data) -> bool:
	if not data is Dictionary: return false
	for key in ["schema_version","absolute_day","minute","inventory","plots","evidence","anchors","claims","relationships","zone","position","ending","name","started","money","flags","foraged","stock_bought","fished","talked","answered","anomaly","heat","repaired","selected_crop","color","hair","pronouns","origin","health","focus","last_attack","last_cast","combat_flash","ability","defeated"]:
		if not data.has(key): return false
	if int(data.schema_version)!=1 or int(data.absolute_day)<1 or float(data.minute)<0 or float(data.minute)>1440 or int(data.money)<0: return false
	for key in ["inventory","plots","evidence","relationships","flags","foraged","stock_bought","talked","answered"]:
		if not data[key] is Dictionary: return false
	for key in ["anchors","claims","position"]:
		if not data[key] is Array: return false
	if data.position.size()!=2 or data.zone not in ["village","house","shop","cave"]: return false
	return true

func save_state(state, path: String = DEFAULT_PATH) -> bool:
	last_error = ""
	if not validate(state.data):
		last_error="Estado inválido. O arquivo anterior foi preservado."
		return false
	var tmp = path+".tmp"
	var file = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		last_error="Não foi possível abrir o arquivo temporário."
		return false
	file.store_string(JSON.stringify(state.data))
	file.flush()
	file.close()
	if not validate(JSON.parse_string(FileAccess.get_file_as_string(tmp))):
		last_error="A verificação falhou. O salvamento anterior foi preservado."
		return false
	if FileAccess.file_exists(path):
		var backup_error = DirAccess.copy_absolute(path,path+".bak")
		if backup_error != OK:
			last_error="Não foi possível criar a cópia anterior."
			return false
	var error = DirAccess.rename_absolute(tmp,path)
	if error != OK:
		last_error="Não foi possível finalizar o salvamento."
		return false
	return true

func load_state(state, path: String = DEFAULT_PATH) -> bool:
	last_error=""
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate)) != OK: continue
		var data = parser.data
		if validate(data):
			state.data=data
			if candidate.ends_with(".bak"): last_error="Cópia anterior recuperada; o arquivo principal estava inválido."
			return true
	last_error="Não há salvamento válido nesta versão. Os arquivos foram preservados."
	return false
