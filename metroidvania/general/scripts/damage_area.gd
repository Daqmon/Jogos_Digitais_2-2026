@icon ( "res://general/icons/damage_area.svg" )
class_name DamageArea extends Area2D

signal damage_taken( attack_area )

@export var audio : AudioStream

func take_damage( attack_area : AttackArea ) -> void:
	damage_taken.emit( attack_area )
	if audio:
		# To be implemented...
		#Audio.play_spatial_sound( audio, global_position )
		pass
		
func make_invunerable( duration : float = 1.0 ) -> void:
	monitorable = false
	await get_tree().create_timer( duration ).timeout
	monitorable = true
