class_name ExplosionEffect extends CPUParticles2D


func _ready() -> void:
	one_shot = true
	amount = 5
	lifetime = 0.4
	explosiveness = 1.0
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	direction = Vector2(1.0, 0.0)
	spread = 180.0
	initial_velocity_min = 80.0
	initial_velocity_max = 200.0
	gravity = Vector2.ZERO
	scale_amount_min = 2.0
	scale_amount_max = 4.0
	color = Color(1.0, 0.85, 0.4, 1.0)
	emitting = true
	finished.connect(queue_free)
