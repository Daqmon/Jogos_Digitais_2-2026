extends CharacterBody2D

@export var speed := 260.0
@export var max_bounces := 2
@export var lifetime := 5.0

var direction := Vector2.RIGHT
var bounces := 0

@onready var attack_area: AttackArea = $AttackArea

func _ready() -> void:
	$AnimatedSprite2D.play("bulletAnimation")
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
	
	# Enable the AttackArea hitbox and destroy bullet when it hits the player
	attack_area.monitoring = true
	attack_area.visible = true
	attack_area.area_entered.connect(_on_attack_area_entered)

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)
	if collision == null:
		return

	if bounces < max_bounces:
		direction = direction.bounce(collision.get_normal())
		bounces += 1
	else:
		queue_free()

func _on_attack_area_entered(area: Area2D) -> void:
	if area is DamageArea:
		# AttackArea's own _on_body_entered signal already calls area.take_damage(self),
		queue_free()
