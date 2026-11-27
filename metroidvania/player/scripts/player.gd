class_name Player extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var attack_sprite_2d: Sprite2D = %AttackSprite2D

@onready var collision_shape_2d_stand: CollisionShape2D = $CollisionShape2DStand
@onready var collision_shape_2d_crouch: CollisionShape2D = $CollisionShape2DCrouch
@onready var one_way_platform_shape_cast: ShapeCast2D = $OneWayPlatformShapeCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: AttackArea = %AttackArea
@onready var health: Health = %Health
@onready var damage_area: DamageArea = %DamageArea
@onready var stun_state : PlayerStateStun = %Stun
@onready var hud: HUD = %HUD
@onready var pause_menu: PauseMenu = %PauseMenu

@export var move_speed : float = 160
@export var max_fall_velocity : float = 600.0
@export var invulnerability_time : float = 1.0

var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : return states[ 0 ]
var previous_state : PlayerState :
	get : return states[ 1 ]
	
var facing_direction : float = 1.0
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980.0
var gravity_multiplier : float = 1.0
var blink_tween : Tween

func _ready() -> void:
	initilize_states()
	damage_area.damage_taken.connect( _on_damage_taken )
	health.died.connect( _on_died )
	hud.bind_health( health )

# Runs everytime a button is pressed (and the input is not consumed by UI)
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build():
		_debug_input( event )
	if event.is_action_released( "jump" ):
		velocity.y *= 0.5
	change_state( current_state.handle_input( event ) )

func _process( _delta: float ) -> void:
	update_direction()
	change_state( current_state.process( _delta ) )

func _physics_process( _delta: float ) -> void:
	velocity.y += gravity * _delta * gravity_multiplier
	velocity.y = clampf( velocity.y, -1000.0, max_fall_velocity )
	move_and_slide()
	change_state( current_state.physics_process( _delta ) )
	
func initilize_states() -> void:
	states = []
	
	for c in $States.get_children():
		if c is PlayerState:
			c.player = self
			states.append( c )
	
	if states.size() == 0:
		return
	
	for state in states:
		state.init()

	current_state.enter()
	$Label.text = current_state.name
		
func change_state( new_state : PlayerState ) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
		
	if current_state:
		current_state.exit()
		
	states.push_front( new_state )
	current_state.enter()
	states.resize( 3 )
	$Label.text = current_state.name
	
func _on_damage_taken( attack_area : AttackArea ) -> void:
	if health.is_dead():
		return
	health.take_damage( attack_area.damage )
	if health.is_dead():
		return
	damage_area.make_invunerable( invulnerability_time )
		# Knock back away from whatever hit us, then stun.
	var dir := signf( global_position.x - attack_area.global_position.x )
	if dir == 0.0:
		dir = 1.0
	stun_state.knockback_dir = dir
	change_state( stun_state )
	_blink( invulnerability_time )

func _on_died() -> void:
	pause_menu.enabled = false
	damage_area.set_deferred( "monitorable", false )
	if blink_tween:
		blink_tween.kill()
	sprite_2d.modulate.a = 1.0
	change_state( current_state.dead )

# Flickers the sprite while the player is invulnerable
func _blink( duration : float ) -> void:
	if blink_tween:
		blink_tween.kill()
	const BLINK_STEP : float = 0.08
	blink_tween = create_tween()
	for i in int( duration / ( BLINK_STEP * 2.0 ) ):
		blink_tween.tween_property( sprite_2d, "modulate:a", 0.25, BLINK_STEP )
		blink_tween.tween_property( sprite_2d, "modulate:a", 1.0, BLINK_STEP )
	blink_tween.tween_property( sprite_2d, "modulate:a", 1.0, 0.0 )

# Debug only (stripped from exported release builds): 1 = take damage, 2 = heal, 3 = +1 max health
func _debug_input( event : InputEvent ) -> void:
	if not ( event is InputEventKey and event.pressed and not event.echo ):
		return
	match event.physical_keycode:
		KEY_1: _on_damage_taken( _debug_attack() )
		KEY_2: health.heal( 1 )
		KEY_3: health.max_health += 1

func _debug_attack() -> AttackArea:
	var a : AttackArea = AttackArea.new()
	a.damage = 1
	return a

func update_direction() -> void:
	if health.is_dead():
		direction = Vector2.ZERO
		return
	
	var x_axis = Input.get_axis( "left", "right" )
	var y_axis = Input.get_axis( "up", "down" )
	direction = Vector2(x_axis, y_axis)
	
	# Lock facing direction during the entire combo
	if current_state is PlayerStateAttack or current_state is PlayerStateJumpAttack or current_state is PlayerStateDash:
		return
	
	if direction.x < 0 and facing_direction != -1.0:
		facing_direction = -1.0
		attack_area.flip( -1.0 )
		sprite_2d.flip_h = true
		attack_sprite_2d.flip_h = true
		attack_sprite_2d.position.x = -24
	elif direction.x > 0 and facing_direction != 1.0:
		facing_direction = 1.0
		attack_area.flip( 1.0 )
		sprite_2d.flip_h = false
		attack_sprite_2d.flip_h = false
		attack_sprite_2d.position.x = 24
	
