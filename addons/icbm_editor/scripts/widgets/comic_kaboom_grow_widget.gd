class_name ComicKaboomGrowWidget
extends ComicKaboomBulgeWidget

func _init(serves:ComicKaboomBulgeWidget):
	super(serves.serves)
	property_name = "grow"
	self.serves = serves

func get_adjusted_anchor():
	match label.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return label.anchor + label.get_transform().x * label.width
		HORIZONTAL_ALIGNMENT_CENTER:
			return label.anchor + label.get_transform().x * (label.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return label.anchor

func reposition():
	# Note that this 0.5, and the *2 in set_by_distance are arbitrary (and matcxh and were chosen in the Comic)
	anchor = get_adjusted_anchor() - label.get_transform().y * (label[property_name] * label.font_size / DISTANCE_MULTIPLIER)

func set_by_distance(distance:float):
	label[property_name] = max(1 / label.font_size, distance / label.font_size * DISTANCE_MULTIPLIER)

