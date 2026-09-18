class_name PlayerStateFall extends PlayerState

@export var fall_gravity_multiplier : float = 1.2

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "jump" )
	player.animation_player.pause()
	player.gravity_multiplier = fall_gravity_multiplier
	
func exit() -> void:
	player.gravity_multiplier = 1.0
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state
	
func process( _delta : float ) -> PlayerState:
	set_jump_frame()
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	if player.is_on_floor():
		return idle
	
	player.velocity.x = player.direction.x * player.move_speed
	return next_state

	
func set_jump_frame() -> void:
	# separates the jumping and falling animation frames
	var frame : float = remap( player.velocity.y, 0.0, player.max_fall_velocity, 0.5, 1.0 )
	player.animation_player.seek( frame, true )
	pass
