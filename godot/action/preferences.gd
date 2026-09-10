extends RefCounted
## Presentation settings are independent from campaign progress and old saves.
const PATH='user://presentation.cfg'
var zoom=1.45
var music_volume=.55
var effects_volume=.85
var reduced_motion=false
var large_text=false
func load_settings():
	var f=ConfigFile.new()
	if f.load(PATH)!=OK:return
	zoom=clampf(float(f.get_value('view','zoom',1.45)),1.15,1.8)
	music_volume=clampf(float(f.get_value('audio','music',.55)),0,1)
	effects_volume=clampf(float(f.get_value('audio','effects',.85)),0,1)
	reduced_motion=bool(f.get_value('view','reduced_motion',false))
	large_text=bool(f.get_value('view','large_text',false))
func save_settings():
	var f=ConfigFile.new()
	f.set_value('view','zoom',zoom);f.set_value('view','reduced_motion',reduced_motion);f.set_value('view','large_text',large_text)
	f.set_value('audio','music',music_volume);f.set_value('audio','effects',effects_volume)
	return f.save(PATH)==OK
func safe_rect(viewport:Viewport)->Rect2:
	var size=viewport.get_visible_rect().size
	var r=Rect2(Vector2(24,16),size-Vector2(48,32))
	if OS.get_name()=='Android':
		var screen=Vector2(DisplayServer.screen_get_size())
		var safe=Rect2(DisplayServer.get_display_safe_area())
		if screen.x>0 and screen.y>0 and safe.size.x>0:
			var factor=size/screen
			var area=Rect2(safe.position*factor,safe.size*factor).grow(-12)
			r=r.intersection(area)
	return r
