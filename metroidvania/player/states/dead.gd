class_name PlayerStateDead extends PlayerState

@export var restart_delay : float = 1.5
var can_restart : bool = false

func init() -> void:
	pass
	
func enter() -> void:
	can_restart = false
	player.velocity.x = 0
	player.animation_player.pause()
	player.sprite_2d.modulate = Color( 0.5, 0.5, 0.5 )
	
	await player.get_tree().create_timer( restart_delay ).timeout
	if player.current_state != self:
		return
	can_restart = true
	player.hud.show_restart_prompt()
	
func exit() -> void:
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if can_restart and _event.is_action_pressed( "attack" ):
		player.get_tree().reload_current_scene()
	return next_state
	
func process( _delta : float ) -> PlayerState:
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	player.velocity.x = 0
	return next_state
