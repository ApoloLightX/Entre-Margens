extends RefCounted
## Immutable external content. Progress belongs to ActionState.
var rooms:Array=[]
var combat:Dictionary={}
func _init():
	rooms=JSON.parse_string(FileAccess.get_file_as_string('res://data/action/campaign.json')).rooms
	combat=JSON.parse_string(FileAccess.get_file_as_string('res://data/action/combat.json'))
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
