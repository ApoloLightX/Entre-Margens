extends Node
## Recorded score and Foley. Capped voices with independent sound variation.
var game
var music:AudioStreamPlayer
var music_b:AudioStreamPlayer
var players:Array=[]
var current=''
var tracks={}
var sfx={}
var serials={}
var targets=[0.0,0.0]
var active=0
var music_gain=.55
var fx_gain=.85
var variation=RandomNumberGenerator.new()
var duck_time=0.0
var music_duck=1.0
const PRIORITY={'hurt':4,'contrapeso_break':4,'heavy':3,'hit':3,'block':3,'cordao':3,'fratura':3,'contrapeso':3,'windup':2,'enemy':2,'body':1}
const FILES={
 'hit':['impactMetal_medium_000','impactMetal_medium_002','impactMetal_medium_004'],
 'heavy':['impactMetal_heavy_001','impactMetal_heavy_003'],
 'body':['impactPunch_heavy_000','impactPunch_heavy_003'],
 'block':['impactMetal_light_001','impactMetal_light_003'],
 'swing':['knifeSlice','knifeSlice2','cloth3'],
 'dodge':['cloth1','cloth2','cloth4'],
 'cordao':['impactBell_heavy_000','impactBell_heavy_002'],
 'fratura':['impactGlass_heavy_001','impactGlass_heavy_003'],
 'contrapeso':['impactMetal_light_001','impactBell_heavy_002'],
 'contrapeso_break':['impactGlass_heavy_001','impactGlass_heavy_003'],
 'windup':['metalLatch'],
 'enemy':['impactMetal_light_001','impactMetal_light_003'],
 'hurt':['impactPunch_medium_000','impactPunch_medium_002'],
 'chime':['handleCoins','handleCoins2'],
 'ui':['bookFlip1','bookFlip2','bookFlip3'],
 'break':['impactMining_000','impactMining_003']
}
const PITCH_IDENTITY={'cordao':1.16,'fratura':.86,'contrapeso':1.02,'contrapeso_break':1.20}
func _ready():
	variation.randomize()
	music=AudioStreamPlayer.new();music.volume_db=-60;add_child(music)
	music_b=AudioStreamPlayer.new();music_b.volume_db=-60;add_child(music_b)
	for key in ['margem','regulador']:
		var stream=load('res://assets/audio/music/'+key+'.ogg');stream.loop=true;tracks[key]=stream
	for key in FILES:
		sfx[key]=[]
		for file in FILES[key]:sfx[key].append(load('res://assets/audio/sfx/'+file+'.ogg'))
	for surface in ['snow','concrete','wood']:
		sfx[surface]=[]
		for i in range(5):sfx[surface].append(load('res://assets/audio/sfx/footstep_'+surface+'_00'+str(i)+'.ogg'))
	for i in range(12):
		var p=AudioStreamPlayer.new();p.volume_db=-10;add_child(p);players.append(p)
	apply_volumes()
func apply_volumes():
	music_gain=game.preferences.music_volume;fx_gain=game.preferences.effects_volume
func set_mood(_anomaly:bool,boss:bool):
	var key='regulador' if boss and game.combat.boss_active else 'margem'
	if key==current:return
	current=key;active=1-active
	var p=music if active==0 else music_b
	p.stream=tracks[key];p.volume_db=-60;p.play()
	targets[active]=1;targets[1-active]=0
func _process(dt):
	if game==null:return
	if duck_time>0:duck_time=maxf(0,duck_time-dt)
	else:music_duck=move_toward(music_duck,1.0,dt*4.8)
	var want_boss=game.combat.boss_active
	if (current=='regulador')!=want_boss:set_mood(game.state.anomaly,want_boss)
	var streams=[music,music_b]
	for i in range(2):
		var p=streams[i]
		p.stream_paused=game.app_paused
		var goal=targets[i]*music_gain*(.50 if game.modal else .70)*music_duck
		if game.state.muted:goal=0
		p.volume_linear=move_toward(p.volume_linear,goal,dt*.45)
		p.pitch_scale=lerpf(p.pitch_scale,.987 if game.state.anomaly and current=='margem' else 1.0,minf(1,dt*.6))
		if targets[i]==0 and p.volume_linear<.001 and p.playing:p.stop()
func duck(seconds=.12,level=.75):
	duck_time=maxf(duck_time,float(seconds));music_duck=minf(music_duck,float(level))
func effect(id:String,gain=1.0):
	if game.state.muted or fx_gain<=0 or not sfx.has(id):return
	var index=int(serials.get(id,0));serials[id]=index+1
	var voice=null;var priority=int(PRIORITY.get(id,0))
	for p in players:
		if not p.playing:
			voice=p;break
	if voice==null:
		for p in players:
			if int(p.get_meta('priority',0))<priority:
				if voice==null or int(p.get_meta('priority',0))<int(voice.get_meta('priority',0)):voice=p
	if voice==null:return
	voice.stop();voice.stream=sfx[id][index%sfx[id].size()]
	voice.set_meta('priority',priority);voice.set_meta('sound',id)
	voice.volume_linear=fx_gain*gain*.58*variation.randf_range(.92,1.04)
	var identity=float(PITCH_IDENTITY.get(id,1.0))
	voice.pitch_scale=variation.randf_range(.96,1.035)*identity*(.82 if id=='body' else (1.10 if id=='block' else 1.0))
	voice.play()
func footstep(surface:String):
	var floor_id='wood' if surface=='planks' else 'concrete'
	if surface=='snow' or game.state.room==0:floor_id='snow' if game.world.road_distance(game.state.position)>80 else 'concrete'
	effect(floor_id,.34)
func toggle():
	apply_volumes()
	if not game.state.muted:
		var p=music if active==0 else music_b
		if not p.playing:p.play()
func shutdown():
	for p in [music,music_b]+players:
		if is_instance_valid(p):p.stop();p.stream=null
	tracks.clear();sfx.clear()
func _exit_tree():shutdown()
