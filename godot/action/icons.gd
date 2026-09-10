extends RefCounted
## One icon vocabulary shared by the HUD and touch controls.
static var cache:Dictionary={}
const PATHS={
	'attack':'<path d="m10 22 13-15 5-3-2 6-14 14M6 19l9 8M10 24l-5 5"/>',
	'dodge':'<path d="m7 7 8 9-8 9m11-18 8 9-8 9"/>',
	'cordao':'<circle cx="16" cy="16" r="10"/><path d="M16 2v8m0 12v8M2 16h8m12 0h8"/>',
	'fratura':'<path d="m22 3-12 12 9 2-10 12M7 9l4 2m12 10 3 3"/>',
	'diary':'<path d="M5 5h18a3 3 0 0 1 3 3v20H8a3 3 0 0 1-3-3ZM10 5v23m5-16h6m-6 5h6"/>',
	'map':'<path d="m3 8 8-3 10 4 8-3v19l-8 3-10-4-8 3Zm8-3v19M21 9v19"/>',
	'pause':'<path d="M11 6v20M22 6v20"/>',
	'heal':'<path d="M16 5v22M5 16h22"/>',
	'vigor':'<path d="M16 27 5 16C-2 4 11 0 16 9c5-9 18-5 11 7Z"/>',
	'focus':'<path d="m16 3 10 13-10 13L6 16Zm0 7v12"/>'
}
static func texture(id:String)->Texture2D:
	if not cache.has(id):
		var img=Image.new()
		var svg='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 32 32"><g fill="none" stroke="white" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">'+PATHS.get(id,PATHS.focus)+'</g></svg>'
		img.load_svg_from_string(svg);cache[id]=ImageTexture.create_from_image(img)
	return cache[id]
static func paint(canvas:CanvasItem,id:String,center:Vector2,color:Color,size=36.0):
	canvas.draw_texture_rect(texture(id),Rect2(center-Vector2.ONE*size/2,Vector2.ONE*size),false,color)
