extends RefCounted
## Lightweight encounter director for the first action-RPG slice.
var state
var foes:Array=[]
var elapsed=0.0

func _init(s) -> void:
	state=s
	reset_zone()

func reset_zone() -> void:
	foes=[]
	if state.data.zone=="cave":
		foes=[{"id":"echo_1","name":"Eco de Cristal","pos":Vector2(830,330),"hp":48,"max_hp":48,"cooldown":0.0,"kind":"echo"},{"id":"echo_2","name":"Eco de Cristal","pos":Vector2(960,520),"hp":36,"max_hp":36,"cooldown":0.0,"kind":"echo"}]

func tick(delta:float,player:Vector2) -> void:
	elapsed+=delta
	for f in foes:
		if f.hp<=0:continue
		f.cooldown=maxf(0.0,float(f.cooldown)-delta)
		var d=player.distance_to(f.pos)
		if d<180 and d>42:f.pos=f.pos.move_toward(player,delta*22)
		if d<48 and f.cooldown<=0:
			state.data.health=maxi(0,int(state.data.health)-4);f.cooldown=1.1

func hit_near(point:Vector2,radius:float,damage:int)->int:
	var total=0
	for f in foes:
		if f.hp>0 and f.pos.distance_to(point)<=radius:f.hp=maxi(0,int(f.hp)-damage);total+=damage
	return total

func ability_hit(point:Vector2,id:String)->int:
	var damage=int({"cordao":14,"fratura":26,"silencio":40}.get(id,0));var radius=float({"cordao":90,"fratura":140,"silencio":125}.get(id,0));return hit_near(point,radius,damage)

func alive()->int:
	var n=0
	for f in foes:
		if f.hp>0:n+=1
	return n
