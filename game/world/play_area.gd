extends RefCounted


static func bounds_for(node: Node2D, margin: float = 0.0) -> Rect2:
	var inset := Vector2(margin, margin)
	return Rect2(inset, node.get_viewport_rect().size - inset * 2.0)


static func center_for(node: Node2D) -> Vector2:
	return bounds_for(node).get_center()


static func keep_inside(node: Node2D, margin: float) -> void:
	var bounds := bounds_for(node, margin)
	node.global_position = Vector2(
		clampf(node.global_position.x, bounds.position.x, bounds.end.x),
		clampf(node.global_position.y, bounds.position.y, bounds.end.y)
	)


static func random_edge_position(node: Node2D, margin: float) -> Vector2:
	return edge_position(node, randi_range(0, 3), margin)


static func edge_position(node: Node2D, edge: int, margin: float) -> Vector2:
	var bounds := bounds_for(node, margin)
	match edge:
		0:
			return Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
		1:
			return Vector2(bounds.end.x, randf_range(bounds.position.y, bounds.end.y))
		2:
			return Vector2(randf_range(bounds.position.x, bounds.end.x), bounds.end.y)
		_:
			return Vector2(bounds.position.x, randf_range(bounds.position.y, bounds.end.y))
