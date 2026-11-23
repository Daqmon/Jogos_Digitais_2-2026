extends Sprite2D

@export var base_alpha : float = 1.0

func _ready() -> void:
	var tween : Tween = create_tween().set_loops()
	tween.tween_interval( randf_range( 1.5, 4.0 ) )
	for a in [ 0.35, 1.0, 0.5, 1.0, 0.2, 1.0 ]:
		tween.tween_property( self, "modulate:a", a * base_alpha, 0.04 )
