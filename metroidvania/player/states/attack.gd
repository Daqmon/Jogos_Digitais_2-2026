class_name PlayerStateAttack extends PlayerState

# 3-hit combo: attack_1 -> attack_2 -> attack_3 (animations in the AnimationPlayer).
# Pressing "attack" during a swing queues the next one, which starts when the current one ends.

const MAX_COMBO : int = 3

var combo_step : int = 0
var queued : bool = false

# Sprite settings before the attack, restored in exit()
var saved_texture : Texture2D
var saved_hframes : int
var saved_vframes : int
var saved_position : Vector2
var saved_offset : Vector2

func init() -> void:
	pass
	
func enter() -> void:
	var sprite : Sprite2D = player.sprite_2d
	saved_texture = sprite.texture
	saved_hframes = sprite.hframes
	saved_vframes = sprite.vframes
	saved_position = sprite.position
	saved_offset = sprite.offset
	
	next_state = null
	combo_step = 1
	queued = false
	player.velocity.x = 0
	player.animation_player.animation_finished.connect( _on_animation_finished )
	play_swing()
	
func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
	
	# The attack animations swap the sprite sheet, so put back what the other animations expect
	var sprite : Sprite2D = player.sprite_2d
	sprite.texture = saved_texture
	sprite.hframes = saved_hframes
	sprite.vframes = saved_vframes
	sprite.position = saved_position
	sprite.offset = saved_offset
	sprite.frame = 0
	
	next_state = null
	combo_step = 0
	queued = false
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "attack" ) and combo_step < MAX_COMBO:
		queued = true
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state
	
func play_swing() -> void:
	player.animation_player.play( "attack_%d" % combo_step )
	
func _on_animation_finished( _anim_name : StringName ) -> void:
	if queued and combo_step < MAX_COMBO:
		combo_step += 1
		queued = false
		play_swing()
	else:
		# Returned by the base process(), idle then moves to run if a direction is held
		next_state = idle
