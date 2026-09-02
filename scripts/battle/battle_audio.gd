class_name BattleAudio
extends Node

const BGM_BUS := &"BGM"
const SFX_BUS := &"SFX"

@export_category("Battle Music")
@export var bgm_stream: AudioStream
@export_range(-40.0, 6.0, 0.5) var bgm_volume_db: float = -10.0

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}


func _ready() -> void:
	_setup_audio()


func _setup_audio() -> void:
	_ensure_bus(BGM_BUS)
	_ensure_bus(SFX_BUS)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = BGM_BUS
	bgm_player.volume_db = bgm_volume_db
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = SFX_BUS
	add_child(sfx_player)

	if bgm_stream == null:
		push_warning(
			"BattleAudio: No BGM is assigned in the Inspector."
		)
		return

	var playback_stream := bgm_stream.duplicate() as AudioStream
	_enable_loop(playback_stream)

	bgm_player.stream = playback_stream
	bgm_player.play()


func _enable_loop(audio_stream: AudioStream) -> void:
	if audio_stream is AudioStreamMP3:
		(audio_stream as AudioStreamMP3).loop = true

	elif audio_stream is AudioStreamOggVorbis:
		(audio_stream as AudioStreamOggVorbis).loop = true

	elif audio_stream is AudioStreamWAV:
		(audio_stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD
		)


func register_sfx(
	hook: StringName,
	stream: AudioStream
) -> void:
	if stream != null:
		sfx_streams[hook] = stream


func play_sfx(
	hook: StringName,
	pitch: float = 1.0
) -> void:
	if not sfx_streams.has(hook):
		return

	if sfx_player == null:
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
	AudioServer.set_bus_name(
		AudioServer.bus_count - 1,
		bus_name
	)
