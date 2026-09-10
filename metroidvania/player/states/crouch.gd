class_name PlayerStateCrouch extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	player.collision_shape_2d_stand.disabled = true
	player.collision_shape_2d_crouch.disabled = false
	# TEST
	player.sprite_2d.scale.y = 0.5
	player.sprite_2d.position.y = -12
	pass
	
func exit() -> void:
	player.collision_shape_2d_crouch.disabled = true
	player.collision_shape_2d_stand.disabled = false
	# TEST
	player.sprite_2d.scale.y = 1.0
	player.sprite_2d.position.y = -24
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "Jump" ):
		if player.one_way_platform_ray_cast_2d.is_colliding():
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
