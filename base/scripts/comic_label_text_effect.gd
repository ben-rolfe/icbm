#@tool
# Having a class name is handy for picking the effect in the Inspector.
class_name ComicLabelTextEffect
extends RichTextEffect


# To use this effect:
# - Enable BBCode on a RichTextLabel.
# - Register this effect on the label.
# - Use [comic_label_text_effect param=2.0]hello[/comic_label_text_effect] in text.
var bbcode = "effects"

func _process_custom_fx(char_fx):
#	var param = char_fx.env.get("param", 1.0)
	#char_fx.transform.x *= 2
	#char_fx.transform.y *= 2
	#char_fx.transform.origin *= 2
	var rotations:Array = char_fx.env["rot"] if char_fx.env["rot"] is Array else [char_fx.env["rot"]]
	var origin:Vector2 = char_fx.transform.origin
#	char_fx.transform = Transform2D(rotations[char_fx.relative_index] * TAU / 360, Vector2(origin.x * char_fx.env["spread"], origin.y))
	
#	char_fx.transform = Transform2D(char_fx.relative_index * TAU / 4, origin)
	
#	print(char_fx.transform.x.y)
	#var t = Transform2D()
	#t.x *= 2
	#t.y *= 2
	#char_fx.transform = t
	return true
