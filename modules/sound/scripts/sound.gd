# Singleton name is Sound
extends Node

const DIR_MUSIC:String = "res://library/music/"
const DIR_SOUND:String = "res://library/sound/"
const DEFAULT_CROSSFADE_TIME:float = 1.0

var _sound_player:AudioStreamPlayer = AudioStreamPlayer.new()
var _sound_playback:AudioStreamPlaybackPolyphonic
# We use 2 music players, to allow for cross-fades.
var _music_player_a:AudioStreamPlayer = AudioStreamPlayer.new()
var _music_player_b:AudioStreamPlayer = AudioStreamPlayer.new()
var _crossfading:bool = false
var _a_is_primary:bool = true
var _crossfade:float = 0.0
var _crossfade_time:float = DEFAULT_CROSSFADE_TIME
var music_file_name:String = ""

func _init():
	assert(Comic, "Comic must be autoloaded before Random")

	add_child(_sound_player)
	add_child(_music_player_a)
	add_child(_music_player_b)

	Comic.add_code_tag("sound", _sound_tag, true)
	Comic.add_code_tag("music", _music_tag, true)
	Comic.before_save.connect(_before_save)
	Comic.after_load.connect(_after_load)

func _ready():
	_sound_player.stream = AudioStreamPolyphonic.new()
	_sound_player.play()
	_sound_playback = _sound_player.get_stream_playback()

func _process(delta:float):
	if _crossfading:
		if _a_is_primary:
			_crossfade -= delta / _crossfade_time
			if _crossfade < 0:
				_crossfade = 0
				_crossfading = false
		else:
			_crossfade += delta / _crossfade_time
			if _crossfade > 1:
				_crossfade = 1
				_crossfading = false
		_music_player_a.volume_db = linear_to_db(1 - _crossfade)
		_music_player_b.volume_db = linear_to_db(_crossfade)


func _sound_tag(params:Dictionary, contents:Array) -> String:
	play(Comic.execute_embedded_code(contents[0]))
	return ""

func _music_tag(params:Dictionary, contents:Array) -> String:
	play_music(Comic.execute_embedded_code(contents[0]).strip_edges())
	return ""

func play_music(file_name:String, pos:float = 0):
	music_file_name = file_name
	var music_path:String = str(DIR_MUSIC, music_file_name)
	if not ResourceLoader.exists(music_path):
		music_file_name = ""
	var music_player = _music_player_b if _a_is_primary else _music_player_a
	_a_is_primary = not _a_is_primary
	_crossfading = true
	if music_file_name == "":
		# We've been given no file (or one that doesn't exist. Stop the music.
		music_player.stop()
	else:
		music_player.stream = load(music_path)
		music_player.play()
		
func play(file_name:String) -> int:
	var sound_path:String = str(DIR_SOUND, file_name)
	if ResourceLoader.exists(sound_path):
		return _sound_playback.play_stream(load(sound_path))
	return -1

func _before_save():
	#TODO: Save position
	var music_player:AudioStreamPlayer = _music_player_a if _a_is_primary else _music_player_b
	if music_player.playing:
		Comic.vars._music = music_file_name
		Comic.vars._music_pos = music_player.get_playback_position()
	else:
		Comic.vars.erase("_sound_music")
		Comic.vars.erase("_sound_music_pos")
	
func _after_load():
	#TODO: If music is already playing, don't do this.
	if Comic.vars.has("_sound_music"):
		if Comic.vars.has("_sound_music_pos"):
			play_music(Comic.vars._sound_music, Comic.vars._sound_music_pos)
			Comic.vars.erase("_sound_music_pos")
		else:
			play_music(Comic.vars._sound_music)
		Comic.vars.erase("_sound_music")
