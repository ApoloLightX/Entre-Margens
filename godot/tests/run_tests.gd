extends SceneTree
const State=preload("res://core/state.gd")
const Catalog=preload("res://core/catalog.gd")
const Inventory=preload("res://systems/inventory.gd")
const Farming=preload("res://systems/farming.gd")
const Economy=preload("res://systems/economy.gd")
const Relations=preload("res://systems/relationships.gd")
const Memory=preload("res://systems/memory.gd")
const Clock=preload("res://systems/clock.gd")
const Quests=preload("res://systems/quests.gd")
const Foraging=preload("res://systems/foraging.gd")
const Save=preload("res://systems/save_service.gd")
var checks=0
var failures=0

func check(value:bool,message:String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)
	else:print("PASS: "+message)

func _initialize() -> void:
	var c=Catalog.new();var s=State.new();var i=Inventory.new(s,c)
	var f=Farming.new(s,c,i);var e=Economy.new(s,c,i);var r=Relations.new(s,c)
	var m=Memory.new(s,i);var clock=Clock.new(s);var q=Quests.new(s,c,i)
	var gather=Foraging.new(s,i,m,c);var saves=Save.new()
	check(c.validate().is_empty(),"External references are valid")
	check(c.tables.npcs.size()==6,"Six independently addressable NPCs")
	var money=s.data.money;e.buy("quartz");check(s.data.money==money-24 and i.count("quartz")==1,"Purchase atomically exchanges currency for item")
	money=s.data.money;e.buy("quartz");check(s.data.money==money and i.count("quartz")==1,"Insufficient funds leave inventory and balance unchanged")
	s.data.inventory={"fish":60};money=s.data.money;e.buy("root_seed");check(i.count("root_seed")==0 and s.data.money==money,"Full bag does not charge buyer")
	s.data.inventory={"spore":2,"root_seed":1,"moss":3,"fiber":3,"stone":2,"quartz":1}
	f.interact("0");f.interact("0");f.overnight()
	check(s.data.plots["0"].growth==0,"Cold fungus remains dormant")
	f.heat_action();check(s.data.repaired and s.data.heat,"Repair consumes real materials and enables heat")
	check(i.count("fiber")==0 and i.count("stone")==0,"Repair bill paid once")
	f.interact("0");f.overnight();f.interact("0");f.overnight()
	check(s.data.plots["0"].growth==2,"Warm wet fungus matures over two nights")
	f.interact("0");check(i.count("fungus")==2 and not s.data.plots.has("0"),"Harvest exchanges mature plot for produce")
	q.claim("calha");money=s.data.money;q.claim("calha");check(s.data.money==money,"Contract payout idempotent")
	r.greeting("sena");r.answer("sena",0);r.greeting("sena");r.answer("sena",0)
	check(s.data.relationships.sena==3,"Repeated conversation cannot farm trust in one day")
	m.sign();m.survey();check(s.data.evidence.has("sign_before") and not s.data.anomaly,"First day is ordinary and can be documented")
	gather.gather("fiber1","fiber",2);gather.gather("fiber1","fiber",2);check(i.count("fiber")==2,"Forage node cannot be harvested twice in a day")
	e.craft("seal");check(i.count("seal")==1,"Evidence case crafted from external recipe")
	m.anchor("sign_before");check("sign_before" in s.data.anchors,"Chosen proof protected")
	var bag=s.data.inventory.duplicate(true);money=s.data.money
	for n in range(3):clock.new_day();m.overnight()
	check(s.data.absolute_day==4 and s.data.anomaly,"First anomaly triggered only after three nights")
	check(s.data.inventory==bag and s.data.money==money,"Anomaly does not roll back inventory or economy")
	check(s.data.evidence.sign_before.value.contains("Calha 3"),"Protected record retains earlier state")
	m.sign();check(m.enough_evidence(),"Contradiction requires current observation plus independent source")
	m.resolve("isolate");check(s.data.ending=="isolate","Anchored investigation permits local decision")
	q.claim("memory");money=s.data.money;q.claim("memory");m.resolve("observe");check(s.data.money==money and s.data.ending=="isolate","Resolution and reward cannot be repeated or silently overwritten")
	var path="user://test_em.json"
	check(saves.save_state(s,path),"Save written and validated")
	var restored=State.new();check(saves.load_state(restored,path) and restored.data==JSON.parse_string(JSON.stringify(s.data)),"Save round-trip preserves complete domain state")
	s.data.money+=1;check(saves.save_state(s,path),"Second save creates a backup")
	var bad=FileAccess.open(path,FileAccess.WRITE);bad.store_string("{broken");bad.close()
	check(saves.load_state(restored,path) and restored.data.money==money,"Corrupt main save recovers valid previous backup")
	var invalid=s.data.duplicate(true);invalid.schema_version=99;check(not saves.validate(invalid),"Future schema rejected without reinterpretation")
	# Recovery route when original observation was missed.
	s.reset();s.data.absolute_day=4;s.data.anomaly=true;s.data.inventory={"seal":1}
	m.sign();m.survey();m.anchor("survey");m.resolve("observe")
	check(s.data.ending=="observe","Missed initial sign does not softlock investigation")
	# Unprotected evidence actually changes, while the earlier protected case survived.
	s.reset();m.sign();s.data.absolute_day=4;m.overnight()
	check(s.data.evidence.sign_before.get("distorted",false),"Unanchored record is altered by the anomaly")
	s.data.inventory={"seal":1};m.anchor("sign_before")
	check(s.data.anchors.is_empty(),"Altered evidence cannot be retroactively treated as protected")
	# Fishing and repetition bounds.
	s.reset();s.data.absolute_day=2
	for n in range(7):gather.fish(true,false)
	check(i.count("fish")==6,"Daily fishing limit prevents seventh capture")
	check(i.count("tag")==1 and s.data.evidence.has("tag"),"Unique artifact does not duplicate across catches")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	var touch=load("res://scenes/touch_controls.gd").new()
	check(touch.touch_start(2,Vector2(160,555)) and touch.direction==Vector2.ZERO,"Touch joystick captures one finger with a dead zone")
	check(not touch.touch_start(3,Vector2(170,555)),"Second finger cannot steal the movement control")
	touch.update_direction(Vector2(600,555))
	check(touch.direction.is_equal_approx(Vector2.RIGHT),"Long touch drag clamps movement to normal speed")
	touch.touch_end(3)
	check(touch.finger==2,"Releasing another finger does not stop movement")
	touch.touch_end(2)
	check(touch.finger==-1 and touch.direction==Vector2.ZERO,"Releasing movement finger clears input")
	touch.touch_start(4,Vector2(190,555));touch.reset()
	check(touch.direction==Vector2.ZERO and touch.finger==-1,"Opening a menu or suspending clears held touch")
	touch.free()
	print("RESULT: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
