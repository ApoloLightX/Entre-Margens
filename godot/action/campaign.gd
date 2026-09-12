extends RefCounted
## Immutable external content. Progress belongs to ActionState.
var rooms:Array=[]
var combat:Dictionary={}
func _init():
	rooms=JSON.parse_string(FileAccess.get_file_as_string('res://data/action/campaign.json')).rooms
	combat=JSON.parse_string(FileAccess.get_file_as_string('res://data/action/combat.json'))
	# Compatibility normalization for the public 0.5.1 data snapshot: the
	# packaged 1.0+ campaign teaches Counterweight at this existing authored
	# stop. Keep the runtime canonical even when upgrading an old checkout.
	for r in rooms:
		for o in r.objects:
			if o.id=='soleira_dena' and not o.has('technique'):
				o.technique='contrapeso'
				if not o.text.contains('CONTRAPESO'):
					o.text+='\n\nJunto ao tubo há um pequeno contrapeso de manutenção preso a uma cinta. Dena deixou uma instrução curta: firme o equipamento no instante do impacto, deixe a massa receber a pancada e solte antes que ela devolva o tranco. Você aprende CONTRAPESO.'
func room(index:int)->Dictionary:
	return rooms[clampi(index,0,rooms.size()-1)]
func point(d:Dictionary)->Vector2:
	return Vector2(d.x,d.y)
func required_remaining(index:int,done:Array)->Array:
	return room(index).required.filter(func(id):return not id in done)
func object_by_id(id:String)->Dictionary:
	for r in rooms:
		for o in r.objects:
			if o.id==id:return o
	return {}
