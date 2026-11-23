@icon ( "res://general/icons/attack_area.svg" )
class_name AttackArea extends Area2D

@export var damage : int = 1
var _activation_id : int = 0

func _ready() -> void:
	body_entered.connect( _on_body_entered )
	area_entered.connect( _on_body_entered )
	monitorable = false
	monitoring = false
	visible = false

func _on_body_entered( body : Node2D ) -> void:
	if body is DamageArea:
		body.take_damage(self)

func activate( duration : float = 0.1 ) -> void:
	_activation_id += 1
	var current_id := _activation_id
	set_active()
	await get_tree().create_timer( duration, false ).timeout
	if _activation_id == current_id:
		set_active( false )
	
func set_active( value : bool = true ) -> void:
	if not value:
		_activation_id += 1
	monitoring = value
	visible = value
	
func flip( direction_x : float ) -> void:
	if direction_x > 0:
		scale.x = 1
	elif direction_x < 0:
		scale.x = -1
		
