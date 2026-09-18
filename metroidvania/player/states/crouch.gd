class_name PlayerStateCrouch extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	player.animation_player.play( "crouch" )
	player.collision_shape_2d_stand.disabled = true
	player.collision_shape_2d_crouch.disabled = false
	
func exit() -> void:
	player.collision_shape_2d_crouch.disabled = true
	player.collision_shape_2d_stand.disabled = false
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "jump" ):
		player.one_way_platform_shape_cast.force_shapecast_update()
		if player.one_way_platform_shape_cast.is_colliding():
			player.position.y += 4
			return fall
		return jump
	return next_state
	
func process( _delta : float ) -> PlayerState:
	if player.direction.y <= 0.5:
		return idle
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state
