extends RefCounted
## Real-time combat rules. Damage is deterministic and separate from presentation.
var state
var abilities
var enemies

func _init(s, a, e) -> void:
	state=s; abilities=a; enemies=e

func basic_attack(direction:Vector2=Vector2.RIGHT) -> String:
	var now=float(Time.get_ticks_msec())/1000.0
	if now-float(state.data.last_attack)<0.32:return ""
	state.data.last_attack=now
	state.data.combat_flash=0.12
	var hit=enemies.hit_near(Vector2(state.data.position[0],state.data.position[1])+direction.normalized()*42,52,8)
	return "Golpe de margem: %d de dano" % hit if hit>0 else "O golpe corta o ar."

func cast(ability_id:String) -> String:
	var spec=abilities.spec(ability_id)
	if spec.is_empty():return "Técnica desconhecida."
	var now=float(Time.get_ticks_msec())/1000.0
	if now-float(state.data.last_cast)<float(spec.cooldown):return "A técnica ainda está se recompondo."
	if int(state.data.focus)<int(spec.cost):return "Foco insuficiente."
	state.data.focus-=int(spec.cost);state.data.last_cast=now;state.data.combat_flash=0.2
	var p=Vector2(state.data.position[0],state.data.position[1]);var hit=enemies.ability_hit(p,ability_id)
	return "%s • %d dano" % [spec.name,hit]

func tick(delta:float) -> void:
	state.data.focus=minf(100.0,float(state.data.focus)+delta*2.5)
	state.data.combat_flash=maxf(0.0,float(state.data.combat_flash)-delta)
