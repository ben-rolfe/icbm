# Singleton name is Messages
extends CanvasLayer

const MARGIN:Vector2 = Vector2(22,22)
const WIDTH:int = 440
const SPACING:int = 12 # Space between messages
const SLIDE_SPEED:Vector2 = Vector2(18,6)
const DURATION:float = 3

var messages:Array = []

func _init():
	assert(Comic, "Comic must be autoloaded before Messages")
	Comic.add_code_tag("message", _message_tag, true)

func add(text:String, duration:float = DURATION):
	var message:ComicTextBlock = ComicTextBlock.new()
	message.size.x = WIDTH
	message.text = text
	message.position = Vector2(Comic.size.x, MARGIN.y)
	if get_child_count() > 0:
		var last_message:ComicTextBlock = get_child(-1)
		message.position.y = last_message.position.y + last_message.size.y + SPACING
	add_child(message)
	messages.push_back({ "timer": duration, "o":message })
	
func _process(delta):
	var top:float = -INF
	var left:float = Comic.size.x - WIDTH - MARGIN.x
	for i in messages.size():
		if messages[i].o.position.x > left:
			messages[i].o.position.x = max(messages[i].o.position.x - SLIDE_SPEED.x, left)
		else:
			# Once we've fully slid the message in, we start counting down the timer (even if this isn't the top message)
			messages[i].timer -= delta
		if messages[i].timer > 0:
			# Don't slide the message higher than the top margin if its timer is still running.
			top = max(top, MARGIN.y)
		if messages[i].o.position.y > top:
			messages[i].o.position.y = max(messages[i].o.position.y - SLIDE_SPEED.y, top)
		top = messages[i].o.position.y + messages[i].o.size.y + SPACING

	if messages.size() > 0 and messages[0].o.position.y < -messages[0].o.size.y:
		# We've scrolled the top message off the screen - remove it.
		remove_child(messages[0].o)
		messages[0].o.queue_free()
		messages.pop_front()

func _message_tag(params:Dictionary, contents:Array) ->String:
	if params.has("t"):
		add(contents[0], float(params.t))
	else:
		add(contents[0])
	return ""
