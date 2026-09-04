class_name PlayerState extends Node

var player : Player
var next_state: PlayerState

@onready var idle : PlayerStateIdle = %Idle
@onready var run : PlayerStateRun = %Run
@onready var jump : PlayerStateJump = %Jump
@onready var fall : PlayerStateFall = %Fall

func init() -> void:
	pass
	
func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state
	
# process != _process, this function isn't called by the engine automatically
func process( _delta : float ) -> PlayerState:
	return next_state

# physics_process != _physics_process, this function isn't called by the engine automatically	
func physics_process( _delta : float ) -> PlayerState:
	return next_state
