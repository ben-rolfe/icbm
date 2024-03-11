class_name ComicLabelCurvePeriodWidget
extends ComicLabelCurveHeightWidget

func _init(serves:ComicLabelCurveHeightWidget):
	super(serves.label)
	property_name = "curve_period"
	action = Action.SLIDE_H
	self.serves = serves

func reposition():
	# Note that this 0.5, and the *2 in the dragged method, are arbitrary.
	anchor = get_adjusted_anchor() + label.get_transform().x * label[property_name] * label.width / 2

func dragged(global_position:Vector2):
	set_by_distance(get_adjusted_anchor().distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, get_adjusted_anchor(), get_adjusted_anchor() + label.get_transform().x)))
	label.rebuild(false)
	
func set_by_distance(distance:float):
	label[property_name] = distance / label.width * 2

func get_adjusted_anchor():
	match label.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return label.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return label.anchor - label.get_transform().x * (label.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return label.anchor - label.get_transform().x * label.width
