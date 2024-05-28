class_name ComicKaboomWavePeriodWidget
extends ComicKaboomWaveHeightWidget

func _init(serves:ComicKaboomWaveHeightWidget):
	super(serves.kaboom)
	property_name = "wave_period"
	action = Action.SLIDE_H
	self.serves = serves

func reposition():
	# Note that this 0.5, and the *2 in the dragged method, are arbitrary.
	anchor = get_adjusted_anchor() + kaboom.get_transform().x * kaboom[property_name] * kaboom.width / 2

func dragged(global_position:Vector2):
	set_by_distance(get_adjusted_anchor().distance_to(Geometry2D.get_closest_point_to_segment_uncapped(global_position, get_adjusted_anchor(), get_adjusted_anchor() + kaboom.get_transform().x)))
	kaboom.rebuild(false)
	
func set_by_distance(distance:float):
	kaboom[property_name] = distance / kaboom.width * 2

func get_adjusted_anchor():
	match kaboom.align:
		HORIZONTAL_ALIGNMENT_LEFT:
			return kaboom.anchor
		HORIZONTAL_ALIGNMENT_CENTER:
			return kaboom.anchor - kaboom.get_transform().x * (kaboom.width * 0.5)
		HORIZONTAL_ALIGNMENT_RIGHT:
			return kaboom.anchor - kaboom.get_transform().x * kaboom.width
