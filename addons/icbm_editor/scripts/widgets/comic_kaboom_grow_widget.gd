class_name ComicKaboomGrowWidget
extends ComicKaboomBulgeWidget

func _init(serves:ComicKaboomBulgeWidget):
	super(serves.serves)
	property_name = "grow"
	self.serves = serves

func get_adjusted_anchor():
	match kaboom.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return kaboom.anchor + kaboom.get_transform().x * kaboom.width
		HORIZONTAL_ALIGNMENT_CENTER:
			return kaboom.anchor + kaboom.get_transform().x * (kaboom.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return kaboom.anchor

func reposition():
	# Note that this 0.5, and the *2 in set_by_distance are arbitrary (and matcxh and were chosen in the Comic)
	anchor = get_adjusted_anchor() - kaboom.get_transform().y * (kaboom[property_name] * kaboom.font_size / DISTANCE_MULTIPLIER)

func set_by_distance(distance:float):
	kaboom[property_name] = max(1, distance) / kaboom.font_size * DISTANCE_MULTIPLIER

