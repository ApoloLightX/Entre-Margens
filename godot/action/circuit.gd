extends RefCounted
## Nine rotatable two-port pipes. Inlet west of 0, outlet east of 8; cell 4 is isolated.
const SOLVED=[10,10,12,3,0,5,9,6,3]
const DELTAS=[Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
static func rotate(mask:int)->int:return ((mask<<1)&15)|((mask>>3)&1)
static func initial(seed_value:int)->Array:
	var result=SOLVED.duplicate()
	for i in range(9):
		for n in range((i+seed_value)%3+1):result[i]=rotate(result[i])
	return result
static func connected(pipes:Array)->bool:
	if pipes.size()!=9:return false
	var index=0;var entering=8;var visited=[]
	for step in range(12):
		if index in visited or index==4:return false
		visited.append(index)
		var mask=int(pipes[index])
		if mask&entering==0:return false
		var outgoing=mask&(~entering)
		if outgoing==0 or outgoing&(outgoing-1)!=0:return false
		var direction=0
		while (1<<direction)!=outgoing:direction+=1
		var next=Vector2i(index%3,index/3)+DELTAS[direction]
		if index==8 and direction==1:return true
		if next.x<0 or next.y<0 or next.x>2 or next.y>2:return false
		index=next.y*3+next.x;entering=1<<((direction+2)%4)
	return false
static func glyph(mask:int)->String:
	return {0:'●',3:'┗',5:'┃',6:'┏',9:'┛',10:'━',12:'┓'}.get(mask,'?')
