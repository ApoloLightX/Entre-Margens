extends RefCounted
## A separate namespace preserves all legacy life-sim saves.
var room=0
var position=Vector2(290,660)
var health=120.0
var focus=100.0
var done:Array=[]
var evidence:Array=[]
var anchors:Array=[]
var anchor_records:Dictionary={}
var cleared:Array=[]
var parts=0
var upgrades=0
var heals=2
var anomaly=false
var ending=''
var technique='cordao'
var learned:Array=['cordao']
var elapsed=0.0
var deaths=0
var kills=0
var assist=false
var muted=false
var name='Viajante'
var started=false
func max_health()->float:return 120.0+upgrades*15.0
func pack()->Dictionary:
	return {'schema':4,'room':room,'position':[position.x,position.y],'health':health,'focus':focus,'done':done.duplicate(),'evidence':evidence.duplicate(),'anchors':anchors.duplicate(),'anchor_records':anchor_records.duplicate(),'cleared':cleared.duplicate(),'parts':parts,'upgrades':upgrades,'heals':heals,'anomaly':anomaly,'ending':ending,'technique':technique,'learned':learned.duplicate(),'elapsed':elapsed,'deaths':deaths,'kills':kills,'assist':assist,'muted':muted,'name':name,'started':started}
func unpack(d:Dictionary):
	room=int(d.room);position=Vector2(d.position[0],d.position[1])
	for k in ['health','focus','done','evidence','anchors','anchor_records','cleared','parts','upgrades','heals','anomaly','ending','technique','learned','elapsed','deaths','kills','assist','muted','name','started']:
		set(k,d[k])
	health=clampf(health,1,max_health());focus=clampf(focus,0,100)
func reset():
	var fresh=load('res://action/state.gd').new()
	unpack(fresh.pack())
