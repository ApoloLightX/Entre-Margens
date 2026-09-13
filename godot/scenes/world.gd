extends Node2D
## Presentation and local collision only; commands belong to Game/services.
var game
var elapsed = 0.0
var npc_positions: Dictionary = {}
const SKINS = ["#d8a27d", "#936c59", "#e9c1a0", "#674b45"]
const COATS = ["#dab769", "#82a5b3", "#b67c99", "#92b49a"]
var font = ThemeDB.fallback_font

func _process(delta: float) -> void:
	elapsed += delta
	if game == null: return
	if not game.ui.is_open():
		update_npcs(delta)
	queue_redraw()

func update_npcs(delta: float) -> void:
	for id in game.catalog.tables.npcs:
		var n: Dictionary = game.catalog.tables.npcs[id]
		var target: Array = n.schedule[0].position
		for entry in n.schedule:
			if int(game.state.data.minute)/60 >= int(entry.start): target=entry.position
		var point = Vector2(target[0],target[1])
		if not npc_positions.has(id): npc_positions[id]=point
		var current: Vector2 = npc_positions[id]
		# Safe public lane shared by work and evening waypoints.
		var next = point
		if absf(current.x-point.x)>5 and (current.y<460 or point.y<460):
			if absf(current.y-470)>5: next=Vector2(current.x,470)
			else: next=Vector2(point.x,470)
		npc_positions[id]=current.move_toward(next,delta*30)

func player() -> Vector2:
	return Vector2(game.state.data.position[0],game.state.data.position[1])

func move_player(direction: Vector2, delta: float) -> void:
	var pos=player()
	var motion=direction*delta*190
	var next=pos+Vector2(motion.x,0)
	if walkable(next): pos=next
	next=pos+Vector2(0,motion.y)
	if walkable(next): pos=next
	game.state.data.position=[pos.x,pos.y]

func walkable(pos: Vector2) -> bool:
	if game.state.data.zone == "village":
		if not Rect2(45,85,1190,575).has_point(pos): return false
		if pos.x>1040 and pos.y>275 and not Rect2(995,382,205,65).has_point(pos): return false
		for b in game.catalog.tables.world.buildings:
			var r: Array=b.rect
			if Rect2(r[0]-8,r[1]+15,r[2]+16,r[3]-15).has_point(pos): return false
		return true
	return Rect2(245,190,790,440).has_point(pos)

func targets() -> Array:
	var out: Array=[]
	match game.state.data.zone:
		"village":
			for b in game.catalog.tables.world.buildings:
				out.append({"id":b.id,"kind":"building","name":b.name,"pos":b.door})
			for idx in range(game.catalog.tables.world.plots.size()):
				out.append({"id":str(idx),"kind":"plot","name":"Leito %d" % (idx+1),"pos":game.catalog.tables.world.plots[idx]})
			for target in game.catalog.tables.world.targets:
				var obj: Dictionary=target.duplicate()
				obj.kind="object"
				out.append(obj)
			for item in game.catalog.tables.world.forage:
				if not game.state.data.foraged.has(item.id): out.append({"id":item.id,"kind":"forage","name":game.catalog.item_name(item.item),"pos":item.pos,"item":item.item,"amount":item.amount})
			for id in npc_positions:
				var pos: Vector2=npc_positions[id]
				out.append({"id":id,"kind":"npc","name":game.catalog.tables.npcs[id].name,"pos":[pos.x,pos.y]})
		"house":
			out=[{"id":"exit","name":"Voltar à vila","kind":"object","pos":[640,625]},{"id":"bed","name":"Descansar até amanhã","kind":"object","pos":[320,310]},{"id":"bench","name":"Bancada de trabalho","kind":"object","pos":[890,300]},{"id":"journal","name":"Diário de Âncoras","kind":"object","pos":[660,280]}]
		"shop":
			out=[{"id":"exit","name":"Voltar à vila","kind":"object","pos":[640,625]},{"id":"trade","name":"Comprar e vender","kind":"object","pos":[660,320]}]
		"cave":
			out=[{"id":"exit","name":"Voltar à vila","kind":"object","pos":[640,625]},{"id":"regulator","name":"Regulador isolado","kind":"object","pos":[645,285]},{"id":"cavefish","name":"Pescar na água subterrânea","kind":"object","pos":[865,475]}]
			for obj in [{"id":"quartz1","item":"quartz","pos":[380,340],"amount":1},{"id":"rock1","item":"stone","pos":[410,505],"amount":2}]:
				if not game.state.data.foraged.has(obj.id): out.append({"id":obj.id,"kind":"forage","name":game.catalog.item_name(obj.item),"item":obj.item,"amount":obj.amount,"pos":obj.pos})
	return out

func nearest() -> Dictionary:
	var best: Dictionary={}
	var distance=58.0
	for t in targets():
		var point=Vector2(t.pos[0],t.pos[1])
		var d=player().distance_to(point)
		if d<distance:
			best=t
			distance=d
	return best

func rect(x:float,y:float,w:float,h:float,col:String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(col))

func label_at(text:String,pos:Vector2,size:int=15,col:String="#dde8df") -> void:
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_CENTER,-1,size,Color(col))

func tree(x:float,y:float,scale_factor:float=1.0) -> void:
	var s=scale_factor
	draw_ellipse(Vector2(x+3,y+12),Vector2(25,8)*s,Color("#8da4aa"))
	rect(x-4*s,y-25*s,8*s,37*s,"#5c7071")
	for i in range(3):
		var yy=y-30*s-i*19*s
		var w=(32-i*6)*s
		draw_colored_polygon(PackedVector2Array([Vector2(x-w,yy+22*s),Vector2(x,yy-32*s),Vector2(x+w,yy+22*s)]),Color("#42676d"))
		draw_colored_polygon(PackedVector2Array([Vector2(x-w+5*s,yy+10*s),Vector2(x,yy-32*s),Vector2(x+w-5*s,yy+10*s)]),Color("#d2e2dd"))

func draw_ellipse(center:Vector2,radii:Vector2,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(24): points.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radii)
	draw_colored_polygon(points,color)

func actor(pos:Vector2,coat:Color,skin:Color,hair:int=0,moving:bool=false) -> void:
	var x=roundf(pos.x)
	var y=roundf(pos.y)
	var step=2.0*sin(elapsed*9) if moving else 0.0
	draw_ellipse(Vector2(x,y+3),Vector2(12,4),Color(0.08,0.2,0.24,0.25))
	draw_rect(Rect2(x-8,y-8,6,10+step),Color("#354950"))
	draw_rect(Rect2(x+2,y-8,6,10-step),Color("#354950"))
	draw_rect(Rect2(x-11,y-26,22,22),coat.darkened(0.1))
	draw_rect(Rect2(x-13,y-24,5,16),coat)
	draw_rect(Rect2(x+8,y-24,5,16),coat)
	draw_rect(Rect2(x-8,y-40,16,16),skin)
	draw_rect(Rect2(x-9,y-42,18,7),Color("#394a4e") if hair==0 else Color("#b78b60") if hair==1 else Color("#d4d5c9"))
	if hair==1: draw_rect(Rect2(x+6,y-38,5,16),Color("#b78b60"))
	draw_rect(Rect2(x-5,y-32,2,2),Color("#293638"))
	draw_rect(Rect2(x+3,y-32,2,2),Color("#293638"))
	draw_rect(Rect2(x-11,y-24,22,4),Color("#e5c68b"))
	draw_rect(Rect2(x+4,y-23,4,12),Color("#e5c68b"))

func building(b:Dictionary) -> void:
	var a:Array=b.rect
	var x=float(a[0]); var y=float(a[1]); var w=float(a[2]); var h=float(a[3])
	rect(x+10,y+20,w,h,"#91a7aa")
	rect(x,y+12,w,h-12,"#a5b9b8")
	for i in range(5): rect(x,y+40+i*20,w,2,"#90a8a9")
	rect(x+12,y+65,38,35,"#405b67")
	rect(x+15,y+68,32,27,"#e8c993")
	rect(x+29,y+65,3,35,"#6d7870")
	rect(x+w-50,y+65,38,35,"#405b67")
	rect(x+w-47,y+68,32,27,"#e8c993")
	rect(x+w-33,y+65,3,35,"#6d7870")
	rect(x+w/2-18,y+h-57,36,57,"#52636a")
	rect(x+w/2-13,y+h-51,26,45,"#7c7368")
	draw_colored_polygon(PackedVector2Array([Vector2(x-12,y+54),Vector2(x+16,y-6),Vector2(x+w-20,y-6),Vector2(x+w+12,y+54)]),Color(b.roof))
	draw_colored_polygon(PackedVector2Array([Vector2(x-8,y+40),Vector2(x+16,y-6),Vector2(x+w-20,y-6),Vector2(x+w+7,y+40)]),Color("#e0e9df"))
	for i in range(7): rect(x+12+i*(w-24)/7,y+43,3,13+(i%3)*4,"#d4e8e4")
	rect(x+w-42,y-20,19,39,"#747778")
	rect(x+w-44,y-24,23,7,"#becbca")
	for i in range(3):
		var offset=fmod(elapsed*8+i*17,60)
		draw_circle(Vector2(x+w-31+sin(elapsed+i)*5,y-30-offset),6+i*2,Color(0.88,0.94,0.91,0.22*(1-offset/65)))
	label_at(b.name,Vector2(x+12,y+h+34),14,"#375a66")

func _draw() -> void:
	if game==null: return
	if game.state.data.zone=="village": draw_village()
	else: draw_interior()
	var moving=Input.get_vector("move_left","move_right","move_up","move_down").length()>0.1 and not game.ui.is_open()
	actor(player(),Color(COATS[int(game.state.data.color)%4]),Color(SKINS[int(game.state.data.color)%4]),int(game.state.data.hair),moving)
	if game.state.data.zone=="village":
		var hour=float(game.state.data.minute)/60
		var night=clampf(absf(hour-13)/12,0,0.75)
		draw_rect(Rect2(0,60,1280,650),Color(0.10,0.19,0.30,night*0.5))
		for i in range(90):
			var sx=fmod(i*87.37+elapsed*12,1280)
			var sy=65+fmod(i*63.77+elapsed*(13+i%4),635)
			draw_rect(Rect2(sx,sy,2,2),Color(0.95,0.99,1,0.45))
		if game.state.data.anomaly and game.state.data.ending=="":
			draw_rect(Rect2(0,60,1280,650),Color(0.25,0.22,0.4,0.035+sin(elapsed*0.8)*0.015))
	if game.state.data.zone=="cave" and game.enemies!=null:
		for foe in game.enemies.foes:
			if foe.hp<=0:continue
			var fp:Vector2=foe.pos
			draw_circle(fp,22,Color(0.35,0.75,0.78,0.25))
			draw_colored_polygon(PackedVector2Array([fp+Vector2(0,-24),fp+Vector2(19,14),fp+Vector2(-19,14)]),Color("#86c7c6"))
			draw_circle(fp+Vector2(-6,-2),3,Color("#e5d59e"));draw_circle(fp+Vector2(6,-2),3,Color("#e5d59e"))
			draw_rect(Rect2(fp.x-25,fp.y-36,50,5),Color("#2c3946"));draw_rect(Rect2(fp.x-25,fp.y-36,50*float(foe.hp)/float(foe.max_hp),5),Color("#cb6f78"))
	var target=nearest()
	if not target.is_empty():
		var p=Vector2(target.pos[0],target.pos[1])
		draw_arc(p+Vector2(0,5),19,0,TAU,24,Color("#e6bc72"),2)

func draw_village() -> void:
	rect(0,0,1280,720,"#c2d4d5")
	rect(40,70,1200,600,"#d5e0da")
	for i in range(230):
		var x=50+fmod(i*143.27,1160)
		var y=85+fmod(i*83.39,560)
		rect(x,y,3+i%6,2,"#c7d8d4")
	# A public path ties the homes, market, property and water together.
	for r in [Rect2(335,250,70,270),Rect2(335,447,675,62),Rect2(515,220,62,235),Rect2(790,220,60,248),Rect2(990,145,160,70)]:
		draw_rect(r,Color("#b7c9c5"))
	rect(1040,272,240,425,"#466876")
	rect(1040,275,20,410,"#93b4b9")
	for i in range(22):
		var x=1070+(i%4)*53+sin(elapsed+i)*4
		var y=285+i*18
		rect(x,y,25,2,"#739aa8")
	draw_colored_polygon(PackedVector2Array([Vector2(1160,275),Vector2(1240,288),Vector2(1220,330),Vector2(1150,318)]),Color("#b9d4d8"))
	rect(1000,383,200,61,"#8b8170")
	for i in range(17): rect(1002+i*11,386,8,55,"#b1a18a")
	for x in [1005,1080,1180]:
		rect(x,371,8,30,"#665f54");rect(x,435,8,22,"#665f54")
	rect(990,453,6,42,"#686b62")
	rect(968,445,66,24,"#62767b")
	label_at("CALHA %s" % ("8" if game.state.data.anomaly else "3"),Vector2(972,462),11)
	# Home thermal beds.
	for index in range(game.catalog.tables.world.plots.size()):
		var p:Array=game.catalog.tables.world.plots[index]
		rect(p[0]-24,p[1]-17,48,36,"#798784")
		rect(p[0]-20,p[1]-14,40,29,"#5c6460")
		if game.state.data.plots.has(str(index)):
			var plot:Dictionary=game.state.data.plots[str(index)]
			if plot.water: rect(p[0]-19,p[1]+10,38,4,"#82b6c0")
			for j in range(3):
				var xx=p[0]-12+j*11
				var height=6+int(plot.growth)*4
				rect(xx,p[1]-height,3,height,"#a8c9a1")
				if plot.crop=="lantern":
					draw_rect(Rect2(xx-4,p[1]-height-4,11,5),Color("#e8cb88"))
				else: draw_line(Vector2(xx,p[1]-height/2),Vector2(xx+5,p[1]-height),Color("#8eb9ae"),3)
		else:
			for j in range(3): rect(p[0]-14+j*12,p[1]-2,7,2,"#84918a")
		rect(p[0]-21,p[1]+22,42,4,"#cf9970" if game.state.data.heat else "#8b9b9c")
	rect(320,310,15,92,"#8a8780")
	draw_circle(Vector2(336,351),15,Color("#cc9470") if game.state.data.heat else Color("#627b80"))
	draw_arc(Vector2(336,351),10,0,TAU,16,Color("#e3cfa4"),3)
	label_at("LEITOS DE CALOR",Vector2(135,307),13,"#52707b")
	# Outdoor props, storage and communal table.
	for x in [460,490]:
		rect(x,520,25,20,"#8a8f7d");rect(x+2,518,21,4,"#b4b9a4")
	rect(570,495,165,26,"#a7997a")
	for x in [585,625,675,712]: draw_circle(Vector2(x,503),6,Color("#e5d3ac"))
	for i in range(8):
		rect(460+i*45,560+sin(i)*4,29,7,"#b8beb0")
	for b in game.catalog.tables.world.buildings: building(b)
	for p in [[75,195,1],[65,380,1],[95,550,1.2],[400,110,0.8],[710,165,0.8],[980,165,0.9],[1000,585,1],[760,600,0.9],[340,625,1]]: tree(p[0],p[1],p[2])
	# Cave aperture.
	draw_circle(Vector2(1110,142),52,Color("#98adb1"))
	draw_circle(Vector2(1110,150),34,Color("#344e5d"))
	rect(1086,148,48,36,"#344e5d")
	rect(1086,180,48,7,"#c5d9d7")
	label_at("SOLEIRA",Vector2(1078,211),12,"#47626e")
	for obj in game.catalog.tables.world.forage:
		if game.state.data.foraged.has(obj.id): continue
		var p:Vector2=Vector2(obj.pos[0],obj.pos[1])
		if obj.item=="stone":
			draw_circle(p,12,Color("#869ca1"));rect(p.x-8,p.y-7,14,4,"#c2d4d0")
		elif obj.item=="moss":
			draw_circle(p,13,Color("#789c8a"));draw_circle(p+Vector2(3,-3),5,Color("#ddbb76"))
		else:
			for j in range(4): draw_line(p+Vector2(j*4,5),p+Vector2(j*4-4,-12),Color("#759d8a"),3)
	var ordered:Array=npc_positions.keys()
	ordered.sort_custom(func(a,b): return npc_positions[a].y<npc_positions[b].y)
	for id in ordered:
		var p:Vector2=npc_positions[id]
		actor(p,Color(game.catalog.tables.npcs[id].color),Color(SKINS[ordered.find(id)%4]),ordered.find(id)%3)
		label_at(game.catalog.tables.npcs[id].name,p+Vector2(-12,-48),13,"#355661")

func draw_interior() -> void:
	var cave=game.state.data.zone=="cave"
	rect(0,60,1280,650,"#213b4c" if cave else "#334b51")
	rect(210,140,860,520,"#50676b" if cave else "#716c62")
	rect(240,180,800,450,"#687c7d" if cave else "#a28b71")
	for i in range(22):
		rect(242+i*36,182,2,446,"#536e76" if cave else "#917c67")
	for i in range(13): rect(242,182+i*34,795,2,"#617b80" if cave else "#ad9578")
	rect(595,612,90,48,"#d0c4a2")
	label_at("SAÍDA",Vector2(616,650),13,"#dce3d1")
	if cave:
		for p in [[265,210],[975,230],[990,560],[260,560]]: tree(p[0],p[1],0.6)
		draw_circle(Vector2(645,267),53,Color("#3f5c68"))
		draw_arc(Vector2(645,267),42,0,TAU,32,Color("#bfa67a"),4)
		draw_arc(Vector2(645,267),27,0,TAU,6,Color("#92c0c0"),3)
		for j in range(3): draw_line(Vector2(645,310),Vector2(500+j*140,600),Color("#86a9ad"),3)
		label_at("REGULADOR ISOLADO",Vector2(555,205),17)
		draw_ellipse(Vector2(900,460),Vector2(95,60),Color("#304f63"))
		for j in range(6): draw_arc(Vector2(900,460),15+j*10,0,PI,18,Color("#648b9d"),1)
		for t in targets():
			if t.kind=="forage":
				var p=Vector2(t.pos[0],t.pos[1])
				draw_colored_polygon(PackedVector2Array([p+Vector2(-13,6),p+Vector2(-5,-25),p+Vector2(12,-9),p+Vector2(15,8)]),Color("#a4d3d2"))
	elif game.state.data.zone=="house":
		rect(270,225,118,115,"#5c6260");rect(277,231,104,100,"#d6b880")
		rect(283,235,92,26,"#eee2c3");rect(277,274,104,46,"#7e9e9f")
		for i in range(6): rect(280+i*17,280,4,31,"#a4bbaf")
		rect(812,215,170,95,"#696a5e");rect(803,212,188,18,"#c5ad85")
		for i in range(5): rect(825+i*27,236,13,16+i%2*9,"#a4bbae")
		rect(602,228,100,56,"#c0a984");rect(631,230,42,27,"#f0e1bd")
		rect(400,380,440,145,"#927a72")
		for i in range(7): rect(411,386+i*19,418,2,"#b7a08b")
		label_at("CASA DA CALHA",Vector2(534,170),22)
		label_at("Bancada",Vector2(850,330),15)
		label_at("Diário",Vector2(632,306),15)
		# Hearth is warm without a magical infinite-energy claim.
		rect(933,470,65,90,"#696967");rect(941,495,48,48,"#4e4d4e")
		for i in range(3):
			draw_colored_polygon(PackedVector2Array([Vector2(946+i*12,535),Vector2(952+i*12,501+sin(elapsed*3+i)*4),Vector2(962+i*12,535)]),Color("#e9b678"))
	else:
		label_at("VENDA DA MARGEM",Vector2(510,170),22)
		for x in [290,815]:
			rect(x,230,150,210,"#6d705f")
			for row in range(4):
				rect(x,264+row*48,150,8,"#c2b391")
				for col in range(5): rect(x+10+col*27,237+row*48,17,25,"#a6b0a0" if col%2 else "#c4a273")
		rect(545,285,190,45,"#d0b587")
		actor(Vector2(640,275),Color("#c3aa76"),Color("#c59272"),2)
		label_at("NERI • balcão",Vector2(585,353),17)
