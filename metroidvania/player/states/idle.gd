class_name PlayerStateIdle extends PlayerState

func init() -> void:
	pass
	
func enter() -> void:
	if player.previous_state == crouch:
		player.animation_player.play_backwards("crouch")
		await player.animation_player.animation_finished
		if player.current_state != self:
			return
			
	player.animation_player.play( "idle" )
	pass
	
func exit() -> void:
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "jump" ):
		return jump
	return next_state
	
func process( _delta : float ) -> PlayerState:
	if player.direction.x != 0:
		return run
	# Using 0.5 instead of 0 may avoid some joystick related problems on controllers
	elif player.direction.y > 0.5:
		return crouch
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state
