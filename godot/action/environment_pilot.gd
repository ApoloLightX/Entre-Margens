extends RefCounted
## Two authored presentation samples; never used by collision or navigation.
static func region(room_id:String)->Rect2:
	match room_id:
		'porto':return Rect2(100,180,660,490)
		'vereda':return Rect2(590,180,650,560)
	return Rect2()
static func shadow(c:Node2D,width:float,tile:int):
	var spread=width*(.42 if tile in [0,8] else .29)
	var outer=PackedVector2Array([Vector2(-spread,-5),Vector2(-spread*.64,-14),Vector2(spread*.28,-12),Vector2(spread,0),Vector2(spread*.69,12),Vector2(-spread*.38,10)])
	c.draw_colored_polygon(outer,Color(.02,.055,.07,.12))
	var contact=PackedVector2Array()
	for p in outer:contact.append(p*Vector2(.65,.50)+Vector2(-3,0))
	c.draw_colored_polygon(contact,Color(.02,.055,.07,.22))
static func building(c:Node2D,width:float):
	var left=-width/2
	# Snow plane and shaded eave, tied to the existing roof footprint.
	c.draw_colored_polygon(PackedVector2Array([Vector2(left,-172),Vector2(left+width*.38,-178),Vector2(width/2,-157),Vector2(width/2,-114),Vector2(left,-114)]),Color(.40,.57,.66,.12))
	c.draw_rect(Rect2(left,-109,width,7),Color(.08,.19,.25,.36))
	c.draw_line(Vector2(left+2,-101),Vector2(left+2,-8),Color(.82,.9,.91,.20),2)
	c.draw_line(Vector2(width/2-3,-99),Vector2(width/2-3,-5),Color(.10,.20,.24,.34),4)
	for i in range(5):
		var x=left+17+float(i)*(width-34)/4
		c.draw_colored_polygon(PackedVector2Array([Vector2(x,-111),Vector2(x+5,-111),Vector2(x+2,-101-(i%3)*-4)]),Color(.76,.86,.89,.7))
	for x in [-width*.28,width*.28]:
		c.draw_rect(Rect2(x-18,-92,36,5),Color(.05,.13,.18,.6))
		c.draw_rect(Rect2(x-19,-49,39,5),Color('#667b83'))
		c.draw_line(Vector2(x-18,-50),Vector2(x+18,-50),Color('#c5d9dd'),2)
		c.draw_rect(Rect2(x-11,-83,22,6),Color(.97,.83,.59,.34))
	# Short mortar failures, not another texture system over the atlas.
	for x in [left+13,width*.12]:
		c.draw_polyline(PackedVector2Array([Vector2(x,-36),Vector2(x+5,-31),Vector2(x+2,-25)]),Color(.08,.20,.25,.35),1)
static func prop_detail(c:Node2D,tile:int):
	if tile in [3,6,9]:
		c.draw_line(Vector2(-23,-96),Vector2(-23,-38),Color(.75,.86,.90,.35),2)
		c.draw_polyline(PackedVector2Array([Vector2(8,-65),Vector2(3,-61),Vector2(7,-54)]),Color(.06,.16,.20,.45),1)
	elif tile in [4,11]:
		c.draw_line(Vector2(-25,-19),Vector2(20,-19),Color(.84,.88,.83,.45),2)
		c.draw_line(Vector2(26,-34),Vector2(26,6),Color(.07,.17,.22,.44),3)
	elif tile in [5,7]:
		c.draw_line(Vector2(-17,-8),Vector2(-8,-12),Color(.78,.88,.91,.45),2)
