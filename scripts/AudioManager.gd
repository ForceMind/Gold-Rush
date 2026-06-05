extends Node
class_name AudioManagerSingleton

# 音效管理器 - 使用合成音效

var audio_stream_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var sfx_bus: int
var music_bus: int


func _ready() -> void:
	# 创建音频总线
	sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus == -1:
		AudioServer.add_bus()
		sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus, "SFX")

	music_bus = AudioServer.get_bus_index("Music")
	if music_bus == -1:
		AudioServer.add_bus()
		music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus, "Music")


func play_coin_collect() -> void:
	_play_tone(880.0, 0.1, 0.3, true)


func play_enemy_hit() -> void:
	_play_tone(220.0, 0.15, 0.4, false)


func play_enemy_die() -> void:
	_play_tone(440.0, 0.2, 0.5, true)
	_play_tone(660.0, 0.15, 0.3, true, 0.1)


func play_player_hit() -> void:
	_play_tone(150.0, 0.3, 0.6, false)
	_play_tone(100.0, 0.2, 0.4, false, 0.1)


func play_game_over() -> void:
	_play_tone(440.0, 0.3, 0.5, false)
	_play_tone(330.0, 0.3, 0.5, false, 0.2)
	_play_tone(220.0, 0.5, 0.6, false, 0.4)


func play_upgrade_select() -> void:
	_play_tone(523.0, 0.1, 0.3, true)
	_play_tone(659.0, 0.1, 0.3, true, 0.1)
	_play_tone(784.0, 0.15, 0.4, true, 0.2)


func play_shoot() -> void:
	_play_tone(300.0, 0.08, 0.2, false)


func play_freeze() -> void:
	_play_tone(1200.0, 0.15, 0.4, false)
	_play_tone(800.0, 0.2, 0.3, false, 0.1)


func play_pickup_collect() -> void:
	_play_tone(600.0, 0.08, 0.3, true)
	_play_tone(900.0, 0.1, 0.35, true, 0.05)
	_play_tone(1200.0, 0.12, 0.4, true, 0.1)


func play_shield_block() -> void:
	_play_tone(400.0, 0.15, 0.5, false)
	_play_tone(600.0, 0.2, 0.4, true, 0.1)


func play_explosion() -> void:
	_play_tone(100.0, 0.3, 0.6, false)
	_play_tone(80.0, 0.2, 0.5, false, 0.1)
	_play_tone(60.0, 0.15, 0.4, false, 0.2)


func _play_tone(freq: float, duration: float, volume: float, ascending: bool, delay: float = 0.0) -> void:
	if delay > 0:
		await get_tree().create_timer(delay).timeout

	var player := AudioStreamPlayer.new()
	add_child(player)

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = duration + 0.1

	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.bus = "SFX"
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var samples_to_generate := int(duration * 44100)

	for i in range(samples_to_generate):
		var t := float(i) / 44100.0
		var sample: float

		if ascending:
			var current_freq := freq + (freq * 0.5 * t / duration)
			sample = sin(2.0 * PI * current_freq * t) * (1.0 - t / duration)
		else:
			sample = sin(2.0 * PI * freq * t) * (1.0 - t / duration)

		playback.push_frame(Vector2(sample, sample))

	await player.finished
	player.queue_free()
