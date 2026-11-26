class_name PlayerStateStun extends PlayerState

## How long the player loses control after being hit.
## Keep this shorter than the player's invulnerability_time.
@export var stun_time : float = 0.3
## Horizontal speed of the knockback, away from whatever hit the player.
@export var knockback_speed : float = 200.0
## Small upward pop so the hit has some weight. Set to 0 for a flat shove.
@export var knockback_lift : float = 120.0
## How quickly the knockback slows down.
@export var friction : float = 600.0

## Set by player.gd before entering this state: 1 = push right, -1 = push left.
var knockback_dir : float = 1.0
var timer : float = 0.0


func init() -> void:
	pass


func enter() -> void:
	timer = stun_time
	player.velocity.x = knockback_dir * knockback_speed
	player.velocity.y = -knockback_lift
	if player.animation_player.has_animation( "hurt" ):
		player.animation_player.play( "hurt" )


func exit() -> void:
	pass


func handle_input( _event : InputEvent ) -> PlayerState:
	# No attacking, jumping, or dashing while stunned.
	return next_state


func process( _delta : float ) -> PlayerState:
	return next_state


func physics_process( delta : float ) -> PlayerState:
	timer -= delta
	player.velocity.x = move_toward( player.velocity.x, 0.0, friction * delta )
	if timer <= 0.0:
		if player.is_on_floor() == false:
			return fall
		return idle
	return next_state
