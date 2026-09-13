extends Node
## Original placeholder score synthesized locally; no external recording.
var game
var player:AudioStreamPlayer
var enabled=true
var previous_anomaly=false

func _ready() -> void:
	player=AudioStreamPlayer.new()
	player.volume_db=-20
	add_child(player)
	refresh(false)

func _process(_delta:float) -> void:
	if game==null:return
	var changed=bool(game.state.data.anomaly) and game.state.data.ending==""
	if changed!=previous_anomaly:
		previous_anomaly=changed
		refresh(changed)

func refresh(anomaly:bool) -> void:
	var rate=16000
	var duration=12
	var bytes=PackedByteArray();bytes.resize(rate*duration*2)
	var notes=[196.0,246.94,293.66,369.99,293.66,246.94,220.0,196.0]
	for i in range(rate*duration):
		var t=float(i)/rate
		var idx=int(t/1.5)%8
		var phase=fmod(t,1.5)
		var frequency=float(notes[idx])*(0.988 if anomaly and idx==3 else 1.0)
		var envelope=sin(minf(phase/0.09,1.0)*PI/2)*exp(-phase*1.7)
		var value=(sin(TAU*frequency*t)*0.28+sin(TAU*frequency*2*t)*0.06)*envelope
		value+=sin(TAU*98*t)*0.025*sin(PI*t/duration)
		if anomaly and idx==6:value*=0.15
		bytes.encode_s16(i*2,int(clampf(value,-1,1)*32767))
	var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=bytes;stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=rate*duration
	player.stream=stream
	if enabled:player.play()

func toggle() -> void:
	enabled=not enabled
	if enabled: player.play()
	else:player.stop()

func _exit_tree() -> void:
	if is_instance_valid(player):
		player.stop()
		player.stream=null
