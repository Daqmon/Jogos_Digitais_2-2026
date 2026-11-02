class_name PlayerStateAttack extends PlayerState

@export var combo_time_window : float = 0.2
@export var speed : float = 75.0
var timer : float = 0
var combo : int = 0
var attack_anims : Array[String] = [ "attack", "attack_2", "attack_3" ]

@onready var attack_sprite_2d : Sprite2D = %AttackSprite2D

func init() -> void:
	attack_sprite_2d.visible = false
	pass
	
func enter() -> void:
	player.animation_player.animation_finished.connect( _on_animation_finished )
	do_attack()
	
func exit() -> void:
	timer = 0
	combo = 0
	player.animation_player.animation_finished.disconnect( _on_animation_finished )
	next_state = null
	attack_sprite_2d.visible = false
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "attack" ):
		timer = combo_time_window
		pass
	return next_state
	
func process( delta : float ) -> PlayerState:
	timer -= delta
	return next_state
	
func physics_process( _delta : float ) -> PlayerState:
	player.velocity.x = player.direction.x * speed
	return null
	
func do_attack() -> void:
	player.animation_player.play( attack_anims[ combo ] )
	player.attack_area.activate()

func _end_attack() -> void:
	if timer > 0:
		combo = wrapi( combo + 1, 0, attack_anims.size() )
		do_attack()
	else :
		next_state = idle
		
func _on_animation_finished( _anim_name : String ) -> void:
	_end_attack()
