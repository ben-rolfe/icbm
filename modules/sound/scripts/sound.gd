# Singleton name is Sound
extends Node

const DIR_SOUND:String = "res://library/sound/"
const DIR_MUSIC:String = "res://library/sound/music/"
const DIR_AMBIENCE:String = "res://library/sound/ambience/"
const DEFAULT_CROSSFADE_TIME:float = 1.0

var _sound_player:AudioStreamPlayer = AudioStreamPlayer.new()
var _sound_playback:AudioStreamPlaybackPolyphonic
# We use 2 music players, to allow for cross-fades.
var _music_player_a:AudioStreamPlayer = AudioStreamPlayer.new()
var _music_player_b:AudioStreamPlayer = AudioStreamPlayer.new()
var music_crossfading:bool = false
var _a_is_primary:bool = true
var music_crossfade:float = 0.0
var music_crossfade_time:float = DEFAULT_CROSSFADE_TIME
var music_file_name:String = ""
var _ambience_players:Dictionary = {}
var _ambience_players_fading_in:Array = []
var _ambience_players_fading_out:Array = []

func _init():
	assert(Comic, "Comic must be autoloaded before Random")

	add_child(_sound_player)
	add_child(_music_player_a)
	add_child(_music_player_b)

	Comic.add_code_tag("sound", _sound_tag, true)
	Comic.before_saved.connect(_before_saved)
	Comic.before_loaded.connect(_before_loaded)
	Comic.after_loaded.connect(_after_loaded)

func _ready():
	_sound_player.stream = AudioStreamPolyphonic.new()
	_sound_player.play()
	_sound_playback = _sound_player.get_stream_playback()

func _process(delta:float):
	if music_crossfading:
		if _a_is_primary:
			if music_crossfade <= 0 or music_crossfade_time <= 0:
				music_crossfade = 0
				music_crossfading = false
			else:
				music_crossfade -= delta / music_crossfade_time
		else:
			if music_crossfade >= 1 or music_crossfade_time <= 0:
				music_crossfade = 1
				music_crossfading = false
			else:
				music_crossfade += delta / music_crossfade_time
		_music_player_a.volume_db = linear_to_db(1 - music_crossfade)
		_music_player_b.volume_db = linear_to_db(music_crossfade)
	for i in range(_ambience_players_fading_in.size() - 1, -1, -1):
		var ambience_player:AudioStreamPlayer = _ambience_players_fading_in[i]
		var volume = db_to_linear(ambience_player.volume_db)
		volume += delta / DEFAULT_CROSSFADE_TIME
		if volume >= 1:
			volume = 1
			_ambience_players_fading_in.remove_at(i)
		ambience_player.volume_db = linear_to_db(volume)
	for i in range(_ambience_players_fading_out.size() - 1, -1, -1):
		var ambience_player:AudioStreamPlayer = _ambience_players_fading_out[i]
		var volume = db_to_linear(ambience_player.volume_db)
		volume -= delta / DEFAULT_CROSSFADE_TIME
		if volume <= 0:
			_ambience_players_fading_out.remove_at(i)
			ambience_player.volume_db = linear_to_db(0)
			ambience_player.queue_free()
		else:
			ambience_player.volume_db = linear_to_db(volume)


func _sound_tag(params:Dictionary, contents:Array) -> String:
	if params.has("music"):
		play_music(Comic.execute_embedded_code(contents[0]).strip_edges(), params.has("self_restart"), params.get("t", 0))
	elif params.has("start"):
		play_ambience(Comic.execute_embedded_code(contents[0]).strip_edges())
	elif params.has("stop"):
		stop_ambience(Comic.execute_embedded_code(contents[0]).strip_edges())
	else:
		play(Comic.execute_embedded_code(contents[0]).strip_edges())
	return ""

func play_music(file_name:String = "", self_restart:bool = false, t:float = 0):
	if self_restart or music_file_name != file_name:
		music_file_name = file_name
		var music_path:String = str(DIR_MUSIC, music_file_name)
		if not ResourceLoader.exists(music_path):
			music_file_name = ""
		var music_player = _music_player_b if _a_is_primary else _music_player_a
		_a_is_primary = not _a_is_primary
		music_crossfading = true
		if music_file_name == "":
			# We've been given no file (or one that doesn't exist. Stop the music.
			music_player.stop()
		else:
			music_player.stream = load(music_path)
			music_player.seek(t)
			music_player.play()

func play(file_name:String) -> int:
	var sound_path:String = str(DIR_SOUND, file_name)
	if ResourceLoader.exists(sound_path):
		return _sound_playback.play_stream(load(sound_path))
	return -1

func play_ambience(file_name:String):
	var ambience_path:String = str(DIR_AMBIENCE, file_name)
	if ResourceLoader.exists(ambience_path):
		if not _ambience_players.has(file_name):
			var ambience_player:AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(ambience_player)
			_ambience_players[file_name] = ambience_player
			ambience_player.stream = load(ambience_path)
			ambience_player.volume_db = linear_to_db(0)
			ambience_player.play()
			_ambience_players_fading_in.push_back(ambience_player)

func stop_ambience(file_name:String = ""):
	if file_name == "":
		# Empty stop command - stop all ambient sounds
		for key in _ambience_players.keys():
			stop_ambience(key)
	else:
		var ambience_player:AudioStreamPlayer = _ambience_players.get(file_name)
		if ambience_player != null:
			_ambience_players.erase(file_name)
			_ambience_players_fading_in.erase(ambience_player)
			_ambience_players_fading_out.push_back(ambience_player)


func _before_saved():
	#TODO: Save position
	var music_player:AudioStreamPlayer = _music_player_a if _a_is_primary else _music_player_b
	if music_player.playing:
		Comic.vars._sound_music = music_file_name
		Comic.vars._sound_music_pos = music_player.get_playback_position()
	else:
		Comic.vars.erase("_sound_music")
		Comic.vars.erase("_sound_music_pos")
	if _ambience_players.keys().size() > 0:
		Comic.vars._sound_ambient = _ambience_players.keys()
	else:
		Comic.vars.erase("_sound_ambient")
	
func _before_loaded():
	stop_ambience()
	play_music()

func _after_loaded():
	if Comic.vars.has("_sound_music"):
		if Comic.vars.has("_sound_music_t"):
			play_music(Comic.vars._sound_music, false, Comic.vars._sound_music_t)
			Comic.vars.erase("_sound_music_t")
		else:
			play_music(Comic.vars._sound_music)
		Comic.vars.erase("_sound_music")
	if Comic.vars.has("_sound_ambient"):
		for file_name in Comic.vars._sound_ambient:
			play_ambience(file_name)
		Comic.vars.erase("sound_ambient")
