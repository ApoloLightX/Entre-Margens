extends RefCounted
## Atomic replacement and one backup; no monotonic runtime cooldowns are persisted.
const PATH='user://entre_margens_action_v4.json'
func valid(d)->bool:
	if not d is Dictionary or d.get('schema',0)!=4:return false
	var defaults=load('res://action/state.gd').new().pack()
	for k in defaults:
		if not d.has(k):return false
		if typeof(defaults[k])==TYPE_DICTIONARY and not d[k] is Dictionary:return false
		if typeof(defaults[k])==TYPE_ARRAY and not d[k] is Array:return false
		if typeof(defaults[k])==TYPE_STRING and not d[k] is String:return false
		if typeof(defaults[k])==TYPE_BOOL and not d[k] is bool:return false
		if typeof(defaults[k]) in [TYPE_INT,TYPE_FLOAT] and not typeof(d[k]) in [TYPE_INT,TYPE_FLOAT]:return false
	if d.room<0 or d.room>5 or d.position.size()!=2:return false
	for v in d.position:
		if not typeof(v) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v)):return false
	for k in ['health','focus','elapsed']:
		if not is_finite(float(d[k])):return false
	if d.parts<0 or d.upgrades<0 or d.upgrades>3 or d.heals<0 or d.heals>5:return false
	if not d.technique in ['cordao','fratura'] or not d.technique in d.learned:return false
	for k in ['done','evidence','anchors','cleared','learned']:
		for v in d[k]:
			if not v is String:return false
	for id in d.anchors:
		if not id in d.anchor_records or not d.anchor_records[id] is String:return false
	return d.anchors.size()<=3
func read_file(path:String):
	if not FileAccess.file_exists(path):return null
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return null
	var d=parser.data
	return d if valid(d) else null
func load_into(state)->bool:
	var d=read_file(PATH)
	if d==null:d=read_file(PATH+'.bak')
	if d==null:return false
	state.unpack(d);return true
func write(state)->bool:
	var d=state.pack()
	if not valid(d):return false
	var file=FileAccess.open(PATH+'.tmp',FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(d));file.flush();file.close()
	if read_file(PATH+'.tmp')==null:return false
	if read_file(PATH)!=null:
		if DirAccess.copy_absolute(PATH,PATH+'.bak')!=OK:return false
	return DirAccess.rename_absolute(PATH+'.tmp',PATH)==OK
