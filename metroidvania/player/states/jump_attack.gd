class_name PlayerStateJumpAttack extends PlayerState

@export var air_speed : float = 75.0

@onready var attack_sprite_2d : Sprite2D = %AttackSprite2D

func init() -> void:
	pass

func enter() -> void:
	player.animation_player.animation_finished.connect( _on_animation_finished )
	player.animation_player.play( "jump_attack" )
	player.attack_area.activate()

func exit() -> void:
	player.animation_player.animation_finished.disconnect( _on_animation_finished )
	next_state = null
	attack_sprite_2d.visible = false
	player.attack_area.set_active( false )

func handle_input( _event : InputEvent ) -> PlayerState:
	# no combo in the air, so extra attack presses are ignored
	return next_state

func process( _delta : float ) -> PlayerState:
	return next_state

func physics_process( _delta : float ) -> PlayerState:
	if player.is_on_floor():
		return idle
	player.velocity.x = player.direction.x * air_speed
	return next_state

func _on_animation_finished( anim_name : String ) -> void:
	if anim_name == "jump_attack":
		next_state = fall
