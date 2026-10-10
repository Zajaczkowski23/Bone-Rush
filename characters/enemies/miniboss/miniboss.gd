extends "res://characters/enemies/enemy/enemy.gd"


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if health <= 0 or not _is_attacking or sprite.frame >= 3:
		return
	# The ring previews the heavy sword's range during the windup.
	var charge := (float(sprite.frame) + sprite.frame_progress) / 3.0
	draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.25, 0.12, 0.06 + charge * 0.12))
	draw_arc(Vector2.ZERO, attack_range, -PI / 2.0, -PI / 2.0 + TAU * charge, 48, Color(1.0, 0.55, 0.18, 0.8), 2.0, true)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if health <= 0:
		$BossName.hide()
