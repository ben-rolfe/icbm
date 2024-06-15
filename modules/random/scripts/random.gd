# Singleton name is Random
extends Node

var seeded:bool = false
var rng:RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	assert(Comic, "Comic must be autoloaded before Random")
	Comic.add_code_tag("random", _random_tag)
	Comic.add_code_tag("roll", _roll_tag)
	Comic.before_save.connect(_before_save)
	Comic.after_load.connect(_after_load)

func _random_tag(params:Dictionary) -> String:
	_handle_seed_params(params)
	var from:float = 0
	var to:float = 1
	if params.has("from"):
		from = float(params.from)
	if params.has("to"):
		to = float(params.to)
	var r:float = randf_range(from, to) if params.has("unseeded") else rng.randf_range(from, to)
	if params.has("var"):
		return ""
	return str(r)
	
func _roll_tag(params:Dictionary) -> String:
	_handle_seed_params(params)
	var from:int = 1
	var to:int = 6
	if params.has("from"):
		from = int(params.from)
	if params.has("to"):
		to = int(params.to)
	var r:int = randi_range(from, to) if params.has("unseeded") else rng.randi_range(from, to)
	if params.has("var"):
		Comic.set_var(params.var, r)
	if params.has("icon"):
		return str(char(int(str("0x", 2679 + r))))
		#return str("[img]res://modules/random/icons/d", to if from == 1 else str(from, "-", to), "_", r, ".svg[/img]")
	else:
		return str(r)

func _handle_seed_params(params:Dictionary):
	if params.has("set_seed"):
		seeded = true
		if params.set_seed == null:
			rng.randomize()
		else:
			rng.seed = int(params.set_seed)
	elif params.has("clear_seed"):
		seeded = false
		rng.randomize()

	
func _before_save():
	if seeded:
		Comic.vars._random_seed = rng.seed
	else:
		Comic.vars.erase("_random_seed")

func _after_load():
	if Comic.vars.has("_random_seed"):
		seeded = true
		rng.seed = int(Comic.vars._random_seed)
	else:
		seeded = false
