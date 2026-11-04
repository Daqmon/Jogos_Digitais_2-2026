@icon( "res://general/icons/damage_area.svg" )
class_name Health extends Node

# Reusable health component. Anything that needs hit points (player, enemies,
# breakables...) can have a Health node as child.
# It only knows about numbers, who takes the damage is decided by the owner,
# usually through a DamageArea (see damage_area.gd).

signal health_changed( current : int, maximum : int )
signal damaged( amount : int )
signal healed( amount : int )
signal died

@export_range( 1, 20 ) var max_health : int = 5 : set = set_max_health

var current_health : int = 0
var _initialized : bool = false

func _ready() -> void:
	current_health = max_health
	_initialized = true
	health_changed.emit( current_health, max_health )

func take_damage( amount : int ) -> void:
	if amount <= 0 or is_dead():
		return
	current_health = maxi( current_health - amount, 0 )
	damaged.emit( amount )
	health_changed.emit( current_health, max_health )
	if current_health == 0:
		died.emit()

func heal( amount : int ) -> void:
	if amount <= 0 or is_dead():
		return
	var previous : int = current_health
	current_health = mini( current_health + amount, max_health )
	if current_health == previous:
		return
	healed.emit( current_health - previous )
	health_changed.emit( current_health, max_health )

func is_dead() -> bool:
	return current_health <= 0

func set_max_health( value : int ) -> void:
	max_health = maxi( value, 1 )
	if not _initialized:
		return
	current_health = mini( current_health, max_health )
	health_changed.emit( current_health, max_health )
