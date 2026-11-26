class_name PlayerStateDash extends PlayerState

@export var dash_speed : float = 400.0
@export var dash_duration : float = 0.20
@export var dash_cooldown : float = 0.25

var timer : float = 0.0
var cooldown_timer : float = 0.0
var air_dash_used : bool = false
var previous_gravity_multiplier : float = 1.0

func init() -> void:
	pass

func enter() -> void:
	timer = dash_duration
	player.animation_player.play( "dash" )
	previous_gravity_multiplier = player.gravity_multiplier
	if not player.is_on_floor():
		# flat air dash: no gravity, no vertical movement
		air_dash_used = true
		player.gravity_multiplier = 0.0
		player.velocity.y = 0.0

func exit() -> void:
	cooldown_timer = dash_cooldown
	player.gravity_multiplier = previous_gravity_multiplier
	player.velocity.x = player.direction.x * player.move_speed
	next_state = null

func handle_input( _event : InputEvent ) -> PlayerState:
	# no attacking or jumping mid-dash
	return next_state

func process( _delta : float ) -> PlayerState:
	return next_state

func physics_process( delta : float ) -> PlayerState:
	timer -= delta
	player.velocity.x = player.facing_direction * dash_speed
	if timer <= 0.0:
		return idle if player.is_on_floor() else fall
	return null

# Other states call this before switching to dash
func can_dash() -> bool:
	if cooldown_timer > 0.0:
		return false
	return player.is_on_floor() or not air_dash_used

# Built-in Godot callback (not the state machine's physics_process).
# It runs on every state node, so the cooldown and air-dash reset keep
# working while another state is active.
func _physics_process( delta : float ) -> void:
	cooldown_timer = maxf( cooldown_timer - delta, 0.0 )
	if player.is_on_floor():
		air_dash_used = false
