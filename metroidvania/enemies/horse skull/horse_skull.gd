extends CharacterBody2D
## Ground enemy: walks toward the player, does a slow floaty leap once in range,
## and swings a melee attack when the player gets close.
## Touching the enemy's body also hurts the player (ContactArea).
##
## AnimatedSprite2D animations expected:
##   idle (loop), walk (loop), jump (no loop), attack (no loop), death (no loop)
##   (if "death" is missing, the enemy just disappears when it dies)
##
## Required child nodes (names must match):
##   AnimatedSprite2D
##   AttackHitbox  (AttackArea, Layer: none, Mask: 5)  - the melee swing, active on hit_frames
##   ContactArea   (AttackArea, same Layer/Mask)       - body-touch damage, always on while alive
##   Hurtbox       (DamageArea)                        - where the player's attacks land

enum State { WALK, WINDUP, LEAP, ATTACK, DEAD }

@export_group("Health")
@export var max_health := 14

@export_group("Movement")
@export var walk_speed := 40.0
@export var acceleration := 300.0
## The enemy ignores the player beyond this distance.
@export var detection_range := 500.0

@export_group("Leap")
## Starts a leap once the player is closer than this (and farther than leap_min_range).
@export var leap_range := 180.0
## Won't leap when the player is closer than this. It just walks up and attacks instead.
@export var leap_min_range := 120.0
## Upward launch speed. Higher = higher jump.
@export var leap_velocity := 200.0
## Gravity multiplier while leaping. Lower = floatier (1.0 = normal gravity).
@export_range(0.1, 1.0) var leap_gravity_scale := 0.25
## Cap on horizontal speed during the leap.
@export var leap_max_speed := 120.0
## Pause before launching, so the player can read it.
@export var windup_time := 0.4
@export var leap_cooldown := 5.0

@export_group("Melee")
@export var melee_range := 70.0
@export var melee_damage := 2
@export var melee_cooldown := 2.5
## First and last frame of the attack animation that can hurt the player.
@export var hit_frames := Vector2i(9, 10)

@export_group("Contact")
## Damage the player takes from touching the enemy's body.
@export var contact_damage := 1

@export_group("Art")
## Untick if the sprite faces left in the source art.
@export var art_faces_right := true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: AttackArea = $AttackHitbox
@onready var contact_area: AttackArea = $ContactArea
@onready var hurtbox: DamageArea = $Hurtbox

var player: Node2D
var health := 0
var state := State.WALK
var facing := 1
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var state_time := 0.0
var leap_timer := 0.0
var melee_timer := 0.0

var mirror_nodes: Array[Node2D] = []
var mirror_base_x: Array[float] = []


func _ready() -> void:
	for area in [attack_hitbox, contact_area, hurtbox]:
		mirror_nodes.append(area)
		for child in area.get_children():
			if child is CollisionShape2D:
				mirror_nodes.append(child)
	for n in mirror_nodes:
		mirror_base_x.append(n.position.x)
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	attack_hitbox.damage = melee_damage
	contact_area.damage = contact_damage
	_set_area_active(attack_hitbox, false)
	_set_area_active(contact_area, true)
	hurtbox.damage_taken.connect(_on_damage_taken)
	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_frame_changed)
	_play("idle")


func _physics_process(delta: float) -> void:
	leap_timer = maxf(leap_timer - delta, 0.0)
	melee_timer = maxf(melee_timer - delta, 0.0)
	state_time += delta

	match state:
		State.WALK:
			_walk(delta)
		State.WINDUP:
			_windup(delta)
		State.LEAP:
			_apply_gravity(delta, leap_gravity_scale)
		State.ATTACK:
			_attack(delta)
		State.DEAD:
			_dead(delta)

	move_and_slide()

	# Landing check runs after move_and_slide so is_on_floor() is up to date.
	if state == State.LEAP and state_time > 0.1 and velocity.y >= 0.0 and is_on_floor():
		leap_timer = leap_cooldown
		_change_state(State.WALK)


# --- Damage -----------------------------------------------------------------

func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	anim.modulate = Color.RED
	create_tween().tween_property(anim, "modulate", Color.WHITE, 0.15)
	if health <= 0:
		_change_state(State.DEAD)


func _on_damage_taken(attack_area: AttackArea) -> void:
	take_damage(attack_area.damage)
	if state != State.DEAD:
		hurtbox.make_invunerable(0.3)


# --- States -----------------------------------------------------------------

func _walk(delta: float) -> void:
	_apply_gravity(delta)
	var target_x := 0.0

	if player != null:
		var to_player := player.global_position - global_position
		var dist := to_player.length()
		if dist <= detection_range:
			_face(signf(to_player.x))
			if dist <= melee_range:
				if melee_timer <= 0.0:
					_change_state(State.ATTACK)
					return
				# Otherwise stand still until the cooldown ends.
			elif dist <= leap_range and dist > leap_min_range and leap_timer <= 0.0 and is_on_floor():
				_change_state(State.WINDUP)
				return
			else:
				target_x = facing * walk_speed

	velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
	_play("walk" if absf(velocity.x) > 5.0 else "idle")


func _windup(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	if state_time >= windup_time:
		_start_leap()


func _attack(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)


func _dead(delta: float) -> void:
	# Keeps falling if it died in mid-air, and slides to a stop.
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)


# --- Leap -------------------------------------------------------------------

func _start_leap() -> void:
	var dx := facing * 100.0
	if player != null:
		dx = player.global_position.x - global_position.x
		_face(signf(dx))

	# Total time in the air with reduced gravity, used to aim the horizontal speed.
	var air_time := 2.0 * leap_velocity / (gravity * leap_gravity_scale)
	velocity.y = -leap_velocity
	velocity.x = clampf(dx / air_time, -leap_max_speed, leap_max_speed)
	_change_state(State.LEAP)


# --- Helpers ----------------------------------------------------------------

func _change_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0
	match state:
		State.WALK:
			_set_area_active(attack_hitbox, false)
		State.WINDUP:
			_play("idle")
		State.LEAP:
			_play("jump")
		State.ATTACK:
			melee_timer = melee_cooldown
			_play("attack")
		State.DEAD:
			# Turn off everything that can hurt or be hurt. Deferred, because this can run
			# inside a physics callback (the player's hit), where direct changes are blocked.
			_set_area_active(attack_hitbox, false)
			_set_area_active(contact_area, false)
			hurtbox.set_deferred("monitorable", false)
			if anim.sprite_frames.has_animation("death"):
				_play("death")
			else:
				queue_free()


## Switches an AttackArea on or off. Deferred so it is safe to call from physics callbacks.
func _set_area_active(area: AttackArea, active: bool) -> void:
	area.set_deferred("monitoring", active)
	area.visible = active


func _apply_gravity(delta: float, gravity_scale: float = 1.0) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_scale * delta


func _face(dir: float) -> void:
	if dir == 0.0:
		return
	facing = int(dir)
	anim.flip_h = (facing < 0) if art_faces_right else (facing > 0)
	var side := -1.0 if anim.flip_h else 1.0
	for i in mirror_nodes.size():
		mirror_nodes[i].position.x = mirror_base_x[i] * side


func _play(anim_name: String) -> void:
	if anim.animation != anim_name or not anim.is_playing():
		anim.play(anim_name)


# --- Signals ----------------------------------------------------------------

func _on_frame_changed() -> void:
	if state != State.ATTACK or anim.animation != "attack":
		return
	var active := anim.frame >= hit_frames.x and anim.frame <= hit_frames.y
	_set_area_active(attack_hitbox, active)


func _on_animation_finished() -> void:
	if state == State.ATTACK and anim.animation == "attack":
		_change_state(State.WALK)
	elif state == State.DEAD and anim.animation == "death":
		queue_free()
