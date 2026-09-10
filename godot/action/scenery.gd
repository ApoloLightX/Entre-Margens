extends Node2D
## Authored CC0 and CC BY 3.0 atlas tiles, with the same data footprints.
var data:Dictionary={}
var time=0.0
var cold=true
var animate=true
const OVER=preload('res://assets/sprites/tiles/overworld.png')
const DUNGEON=preload('res://assets/sprites/tiles/dungeon.png')
const SNOW=preload('res://assets/sprites/tiles/snow.png')
const HOUSE=preload('res://assets/sprites/tiles/winter-house.png')
const TREES=preload('res://assets/sprites/tiles/winter-trees.png')
func piece(tex:Texture2D,rect:Rect2,target:Rect2,tint=Color.WHITE):
	draw_texture_rect_region(tex,target,rect,tint)
func _draw():
	if data.is_empty():return
	var tile=int(data.tile);var w=float(data.size)
	var tint=Color('#bdcdd1') if cold else Color('#b3c0bc')
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.38))
	draw_circle(Vector2(0,-6),w*.27,Color(0.02,.055,.07,.25))
	draw_set_transform(Vector2.ZERO)
	match tile:
		0,8:
			var width=roundf(w/48)*48
			# Authored snowy roof and brick facade; use central strips to extend width.
			piece(HOUSE,Rect2(0,64,16,64),Rect2(-width/2,-112,32,112),tint)
			piece(HOUSE,Rect2(48,64,16,64),Rect2(width/2-32,-112,32,112),tint)
			for x in range(int((width-64)/32)):
				piece(HOUSE,Rect2(16,64,16,64),Rect2(-width/2+32+x*32,-112,32,112),tint)
			piece(HOUSE,Rect2(0,0,64,64),Rect2(-width/2-8,-200,width+16,96),Color('#bccfd6'))
			for x in [-width*.28,width*.28]:
				draw_rect(Rect2(x-17,-90,34,42),Color('#35424a'))
				draw_rect(Rect2(x-12,-85,24,32),Color('#e9bb78'))
				draw_line(Vector2(x,-85),Vector2(x,-53),Color('#725a43'),3)
				draw_line(Vector2(x-12,-69),Vector2(x+12,-69),Color('#725a43'),3)
			piece(OVER,Rect2(176,480,16,16),Rect2(-22,-50,44,54),Color('#947152'))
		1:
			for x in [-w*.36,w*.36-48]:piece(DUNGEON,Rect2(0,0,16,32),Rect2(x,-118,48,128),tint)
			piece(DUNGEON,Rect2(0,16,32,16),Rect2(-w*.4,-146,w*.8,48),tint)
			piece(DUNGEON,Rect2(256+int(time*7)%4*16,144,16,16),Rect2(-18,-116,36,36),Color('#a3d5d0'))
		2:
			piece(TREES,Rect2(0,0,96,144),Rect2(-w*.36,-w*.98,w*.72,w*1.08),Color('#9bb6c6'))
		3,6,9:
			piece(DUNGEON,Rect2(0,0,16,32),Rect2(-30,-114,60,120),tint)
			piece(DUNGEON,Rect2(80,80,16,16),Rect2(-36,-20,72,30),tint)
		4,11:
			piece(DUNGEON,Rect2(304,272,16,16),Rect2(-32,-46,64,64),Color('#c9a67b'))
			draw_line(Vector2(0,-16),Vector2(0,-60),Color('#39494e'),12)
			draw_line(Vector2(-2,-16),Vector2(-2,-60),Color('#bba179'),4)
			piece(DUNGEON,Rect2(256+(int(time*3)%3)*16,96,16,16),Rect2(-32,-83,64,64),Color('#c9ba8f'))
			piece(DUNGEON,Rect2(256+(int(time*5)%4)*16,144,16,16),Rect2(-13,-63,26,26),Color('#a5cdd0'))
		5:
			piece(SNOW,Rect2(64,192,32,32),Rect2(-36,-48,72,72),Color('#aebcc7'))
		7:
			piece(OVER,Rect2(16,432,16,16),Rect2(-24,-40,48,48),tint)
		10:
			for y in range(3):
				piece(OVER,Rect2(64,480,16,16),Rect2(-60,-100+y*30,120,36),Color('#a18e7b'))
			for i in range(7):draw_rect(Rect2(-50+i*15,-83,8,15),Color('#789b9e') if i%2 else Color('#c5ab7e'))
		12:
			for i in range(5):piece(OVER,Rect2(336,464,16,16),Rect2(-w/2+i*w/5,-42,w/5,58),tint)
		13:
			piece(DUNGEON,Rect2(256+int(time*8)%8*16,0,16,16),Rect2(-24,-68,48,48))
			piece(OVER,Rect2(64,480,16,16),Rect2(-24,-24,48,30),Color('#9c7859'))
		14:
			piece(SNOW,Rect2(32,64,32,32),Rect2(-w*.6,-w*.55,w*1.2,w),Color('#adbfc9'))
		15:
			piece(DUNGEON,Rect2(0,0,32,32),Rect2(-w*.3,-w*.55,w*.6,w*.6),tint)
			piece(DUNGEON,Rect2(256+int(time*9)%8*16,144,16,16),Rect2(-45,-110,90,90),Color('#8abcbf'))
func _process(dt):
	if animate and int(data.get('tile',0)) in [1,4,11,13,15]:
		time+=dt;queue_redraw()
