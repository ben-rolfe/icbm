class_name ComicFeaturedEdgeStyle
extends ComicEdgeStyle
# A parent class for balloon edge styles with irregular features

const SPACING:int = 8


func _init():
	is_randomized = true

func calculate_points(balloon:ComicBalloon):
	# This method primes the balloon.edge_points with points to be used for the feature curve endpoints
	#NOTE: We don't call super() from here - we're doing things quite differently.
	if balloon.edge_offsets.size() > 0:
		var distance:PackedFloat32Array = PackedFloat32Array()
		distance.push_back(0)
		for i in range(1, balloon.edge_offsets.size()):
			distance.push_back(distance[i-1] + balloon.edge_offsets[i].distance_to(balloon.edge_offsets[i-1]))
		# Calculate the control point edge offsets
		var initial_distance:float = balloon.edge_segment_length * balloon.rng.randf_range(SPACING, SPACING * 2)
		var next_distance:float = initial_distance
		for i in balloon.edge_offsets.size():
			if distance[i] >= next_distance:
				balloon.edge_points.push_back(balloon.edge_offsets[i])
				next_distance += balloon.edge_segment_length * balloon.rng.randf_range(SPACING, SPACING * 2)
				var remaining_distance:float = distance[-1] - next_distance
				if remaining_distance < 0:
					# The next point would be past the end of the loop
					var gap_distance = initial_distance + distance[-1] - distance[i]
					if gap_distance > balloon.edge_segment_length * SPACING * 2:
						# The gap is too big.
						next_distance = balloon.rng.randf_range(distance[i] + balloon.edge_segment_length * SPACING, distance[-1] + initial_distance - balloon.edge_segment_length * SPACING)
						if next_distance > distance[-1]:
							# The updated final point is beyond the end of the hidef length
							#Find it, add it, and break out of the loop
							next_distance -= distance[-1]
							for j in distance.size():
								if distance[j] >= next_distance:
									balloon.edge_points.push_back(balloon.edge_offsets[j])
									break # the for j loop
							break # the for i loop
						# else: The updated final point is within the hidef length. Don't break out of the for i loop - we'll add the point when we get to it.
					else:
						#The gap is not too big. Since we've done all this checking, we may as well break out of the loop now, as the next point won't be added.
						break
