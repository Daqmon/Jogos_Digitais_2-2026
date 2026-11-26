extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var max_health := 4
@export var move_speed := 80.0
@export var acceleration := 170.0
@export var preferred_distance := 180.0
@export var attack_distance := 200.0
@export var distance_tolerance := 10.0
@export var detection_range := 400.0
@export var bob_height := 6.0
@export var bob_speed := 3.0
@export var min_ground_clearance := 80.0
@export var max_ground_clearance := 120.0
@export var contact_damage := 1

@onready var contact_area: AttackArea = $ContactArea
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer
@onready var floor_ray: RayCast2D = $RayCast2D
@onready var damage_area: DamageArea = $DamageArea

var player: Node2D
var health: int
var is_attacking := false
var is_dead := false
var time := 0.0
var bob_nodes: Array = []
var bob_base_y: Array = []
var mirror_nodes: Array[Node2D] = []
var mirror_base_x: Array[float] = []

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	anim.animation_finished.connect(_on_animation_finished)
	damage_area.damage_taken.connect(_on_damage_taken)
	floor_ray.target_position = Vector2(0, max_ground_clearance + 20.0)
	contact_area.damage = contact_damage
	contact_area.set_active(true)
	bob_nodes = [anim, damage_area, contact_area, muzzle]
	for n in bob_nodes:
		bob_base_y.append(n.position.y)
	for area in [damage_area, contact_area]:
		mirror_nodes.append(area)
		for child in area.get_children():
			if child is CollisionShape2D:
				mirror_nodes.append(child)
	for n in mirror_nodes:
		mirror_base_x.append(n.position.x)
	anim.play("idle")

func _physics_process(delta: float) -> void:
	if player == null or is_dead:
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()

	# Face the player (flip the comparison if your skull faces left by default)
	anim.flip_h = to_player.x < 0
	muzzle.position.x = absf(muzzle.position.x) * (-1.0 if anim.flip_h else 1.0)
	
	var side := -1.0 if anim.flip_h else 1.0
	for i in mirror_nodes.size():
		mirror_nodes[i].position.x = mirror_base_x[i] * side

	# Approach if too far, back off if too close, hover in between
	var target_velocity := Vector2.ZERO
	if not is_attacking and dist <= detection_range:
		if dist > preferred_distance + distance_tolerance:
			target_velocity = to_player.normalized() * move_speed
		elif dist < preferred_distance - distance_tolerance:
			target_velocity = -to_player.normalized() * move_speed

	# Enforce minimum AND maximum height above the ground
	if floor_ray.is_colliding():
		var floor_y := floor_ray.get_collision_point().y
		var current_clearance := floor_y - global_position.y

		if current_clearance < min_ground_clearance:
			target_velocity.y = minf(target_velocity.y, 0.0)
			target_velocity.y -= (min_ground_clearance - current_clearance) * 4.0
		elif current_clearance > max_ground_clearance:
			target_velocity.y = maxf(target_velocity.y, 0.0)
			target_velocity.y += (current_clearance - max_ground_clearance) * 4.0
	else:
		target_velocity.y = maxf(target_velocity.y, 0.0)
		target_velocity.y += 40.0

	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	move_and_slide()

	time += delta
	var bob := sin(time * bob_speed) * bob_height
	for i in bob_nodes.size():
		bob_nodes[i].position.y = bob_base_y[i] + bob

func _on_damage_taken(attack_area: AttackArea) -> void:
	var knockback_dir := (global_position - attack_area.global_position).normalized()
	take_damage(attack_area.damage, knockback_dir * 170.0)

func take_damage(amount: int = 1, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return

	health -= amount
	velocity += knockback

	# Quick white/red flash feedback (use Color(10, 10, 10) for bright white)
	var tween := create_tween()
	anim.modulate = Color(10.0, 10.0, 10.0)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	shoot_timer.stop()

	# Disable hitboxes/hurtboxes so dead enemy can't hurt or block the player
	$CollisionShape2D.set_deferred("disabled", true)
	damage_area.set_deferred("monitoring", false)
	damage_area.set_deferred("monitorable", false)
	contact_area.set_deferred("monitoring", false)

	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
	else:
		queue_free()

func _on_shoot_timer_timeout() -> void:
	if player == null or is_attacking or is_dead:
		return
	if global_position.distance_to(player.global_position) <= attack_distance:
		is_attacking = true
		anim.play("attack")

func _on_animation_finished() -> void:
	if anim.animation == "attack" and not is_dead:
		shoot()
		is_attacking = false
		anim.play("idle")
	elif anim.animation == "death":
		queue_free()

func shoot() -> void:
	var p = projectile_scene.instantiate()
	p.direction = (player.global_position - muzzle.global_position).normalized()
	get_tree().current_scene.add_child(p)
	p.global_position = muzzle.global_position
