class_name Player extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d_stand: CollisionShape2D = $CollisionShape2DStand
@onready var collision_shape_2d_crouch: CollisionShape2D = $CollisionShape2DCrouch
@onready var one_way_platform_shape_cast: ShapeCast2D = $OneWayPlatformShapeCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var move_speed : float = 100

var states : Array[ PlayerState ]
var current_state : PlayerState :
	get : return states[ 0 ]
var previous_state : PlayerState :
	get : return states[ 1 ]
	
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980.0
var gravity_multiplier : float = 1.0

func _ready() -> void:
	initilize_states()

# Runs everytime a button is pressed (and the input is not consumed by UI)
func _unhandled_input(event: InputEvent) -> void:
	change_state( current_state.handle_input( event ) )

func _process( _delta: float ) -> void:
	update_direction()
	change_state( current_state.process( _delta ) )

func _physics_process( _delta: float ) -> void:
	velocity.y += gravity * _delta * gravity_multiplier
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
	
# This treatment is done outside of _unhandled_input because it needs constant checking
func update_direction() -> void:
	var prev_direction : Vector2 = direction
	
	var x_axis = Input.get_axis( "left", "right" )
	var y_axis = Input.get_axis( "up", "down" )
	direction = Vector2(x_axis, y_axis)
	
	if prev_direction.x != direction.x:
		if direction.x < 0:
			sprite_2d.flip_h = true
		elif direction.x > 0:
			sprite_2d.flip_h = false
	
