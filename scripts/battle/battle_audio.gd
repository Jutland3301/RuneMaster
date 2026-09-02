class_name BattleAudio
extends Node

const BGM_BUS := &"BGM"
const SFX_BUS := &"SFX"

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}


func setup(bgm_stream: AudioStream) -> void:
	_ensure_bus(BGM_BUS)
	_ensure_bus(SFX_BUS)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BattleBGM"
	bgm_player.bus = BGM_BUS
	bgm_player.volume_db = -10.0
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "BattleSFX"
	sfx_player.bus = SFX_BUS
	add_child(sfx_player)

	if bgm_stream == null:
		push_warning("Basic Battle BGM 1 was not found; battle will run silently.")
		return

	if bgm_stream is AudioStreamOggVorbis:
		(bgm_stream as AudioStreamOggVorbis).loop = true
	elif bgm_stream is AudioStreamWAV:
		(bgm_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

	bgm_player.stream = bgm_stream
	bgm_player.play()


func register_sfx(hook: StringName, stream: AudioStream) -> void:
	if stream != null:
		sfx_streams[hook] = stream


func play_sfx(hook: StringName, pitch: float = 1.0) -> void:
	if not sfx_streams.has(hook) or sfx_player == null:
		return

	sfx_player.stream = sfx_streams[hook]
	sfx_player.pitch_scale = pitch
	sfx_player.play()


func stop_bgm() -> void:
	if bgm_player != null:
		bgm_player.stop()


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
