class_name HUD extends CanvasLayer

# In-game HUD. It lives inside player.tscn so every scene that has a Player
# (levels, playground) gets it for free. It only listens to signals, it never
# changes game state by itself.

const HEART_FULL : Texture2D = preload( "res://hud/sprites/heart_full.png" )
const HEART_EMPTY : Texture2D = preload( "res://hud/sprites/heart_empty.png" )
const LOW_HEALTH_RATIO : float = 0.3

@onready var hearts_container : HBoxContainer = %HeartsContainer
@onready var game_over : Control = %GameOver
@onready var restart_prompt : Label = %RestartPrompt

var _health : Health
var _hearts : Array[ TextureRect ] = []
var _low_health_tween : Tween

func _ready() -> void:
	game_over.visible = false
	restart_prompt.visible = false
	restart_prompt.text = "Pressione %s para tentar de novo" % _get_action_key_name( "attack" )

# Called by the Player, keeps the HUD decoupled from the player's internals.
func bind_health( health : Health ) -> void:
	if _health:
		_health.health_changed.disconnect( _on_health_changed )
		_health.died.disconnect( _on_died )
	_health = health
	_health.health_changed.connect( _on_health_changed )
	_health.died.connect( _on_died )
	_on_health_changed( _health.current_health, _health.max_health )

func show_restart_prompt() -> void:
	restart_prompt.visible = true

func _on_health_changed( current : int, maximum : int ) -> void:
	if _hearts.size() != maximum:
		_rebuild_hearts( maximum )
	for i in _hearts.size():
		_hearts[ i ].texture = HEART_FULL if i < current else HEART_EMPTY
	_update_low_health_warning( current, maximum )

func _on_died() -> void:
	game_over.modulate.a = 0.0
	game_over.visible = true
	var tween : Tween = create_tween()
	tween.tween_property( game_over, "modulate:a", 1.0, 0.8 )

func _rebuild_hearts( amount : int ) -> void:
	for h in _hearts:
		h.queue_free()
	_hearts.clear()
	for i in amount:
		var heart : TextureRect = TextureRect.new()
		heart.texture = HEART_FULL
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		hearts_container.add_child( heart )
		_hearts.append( heart )

# Pulses the hearts while the player is almost dead
func _update_low_health_warning( current : int, maximum : int ) -> void:
	if _low_health_tween:
		_low_health_tween.kill()
	hearts_container.modulate = Color.WHITE
	if current <= 0 or float( current ) / maximum > LOW_HEALTH_RATIO:
		return
	_low_health_tween = create_tween().set_loops()
	_low_health_tween.tween_property( hearts_container, "modulate", Color( 1.0, 0.45, 0.45 ), 0.4 )
	_low_health_tween.tween_property( hearts_container, "modulate", Color.WHITE, 0.4 )

func _get_action_key_name( action : StringName ) -> String:
	for event in InputMap.action_get_events( action ):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return action
