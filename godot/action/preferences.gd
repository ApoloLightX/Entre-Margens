extends RefCounted
## Presentation settings are independent from campaign progress and old saves.
const PATH='user://presentation.cfg'
const CAMERA_REVISION=1
const DEFAULT_ZOOM=1.0
const MIN_ZOOM=.9
const MAX_ZOOM=1.8
var zoom=DEFAULT_ZOOM
var music_volume=.55
var effects_volume=.85
var reduced_motion=false
var large_text=false
func load_settings():
	var f=ConfigFile.new()
	if f.load(PATH)!=OK:return
	var migrate_camera=int(f.get_value('view','camera_revision',0))<CAMERA_REVISION
	zoom=DEFAULT_ZOOM if migrate_camera else clampf(float(f.get_value('view','zoom',DEFAULT_ZOOM)),MIN_ZOOM,MAX_ZOOM)
	music_volume=clampf(float(f.get_value('audio','music',.55)),0,1)
	effects_volume=clampf(float(f.get_value('audio','effects',.85)),0,1)
	reduced_motion=bool(f.get_value('view','reduced_motion',false))
	large_text=bool(f.get_value('view','large_text',false))
	# Migrate once, retaining later player choices and unrelated settings.
	if migrate_camera:save_settings()
func save_settings():
	var f=ConfigFile.new()
	f.load(PATH)
	f.set_value('view','camera_revision',CAMERA_REVISION)
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
