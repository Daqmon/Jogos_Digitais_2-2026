class_name HUD extends CanvasLayer

const HEART_FULL : Texture2D = preload( "res://hud/sprites/heart_full.png" )
const HEART_EMPTY : Texture2D = preload( "res://hud/sprites/heart_empty.png" )
const LOW_HEALTH_RATIO : float = 0.3
const BEAT_PERIOD : float = 1.6
const BEAT_PERIOD_LOW : float = 0.6
const FLASH : Color = Color( 3.0, 3.0, 3.0 )

@onready var hearts_container : HBoxContainer = %HeartsContainer
@onready var skull_icon : TextureRect = %SkullIcon
@onready var fx : Control = %Fx
@onready var game_over : Control = %GameOver
@onready var restart_prompt : Label = %RestartPrompt

var _health : Health
var _hearts : Array[ TextureRect ] = []
var _displayed_health : int = -1
var _low_health_tween : Tween
var _beat_tween : Tween
var _skull_tween : Tween

func _ready() -> void:
	game_over.visible = false
	restart_prompt.visible = false
	restart_prompt.text = "Pressione %s para tentar de novo" % _get_action_key_name( "attack" )
	skull_icon.pivot_offset = skull_icon.texture.get_size() / 2.0

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
	var blink : Tween = create_tween().set_loops()
	blink.tween_property( restart_prompt, "modulate:a", 0.35, 0.6 )
	blink.tween_property( restart_prompt, "modulate:a", 1.0, 0.6 )

func _on_health_changed( current : int, maximum : int ) -> void:
	var first_time : bool = _displayed_health < 0
	var previous : int = mini( _displayed_health, maximum )
	_sync_heart_count( maximum, first_time )

	var lost_index : int = 0
	for i in range( _hearts.size() - 1, -1, -1 ):
		var heart : TextureRect = _hearts[ i ]
		var was_full : bool = i < previous
		var is_full : bool = i < current
		if first_time:
			heart.texture = HEART_FULL if is_full else HEART_EMPTY
		elif was_full and not is_full:
			_animate_lose( heart, lost_index * 0.07 )
			lost_index += 1
		elif is_full and not was_full:
			_animate_gain( heart, ( current - 1 - i ) * 0.07 )
	if lost_index > 0:
		_shake_skull()

	_displayed_health = current
	_update_low_health_warning( current, maximum )
	_update_heartbeat( current, maximum )

func _on_died() -> void:
	game_over.modulate.a = 0.0
	game_over.visible = true
	var tween : Tween = create_tween()
	tween.tween_property( game_over, "modulate:a", 1.0, 0.8 )

# Adds/removes hearts so the container always has `amount` of them
func _sync_heart_count( amount : int, intro : bool ) -> void:
	while _hearts.size() > amount:
		_hearts.pop_back().queue_free()
	while _hearts.size() < amount:
		var heart : TextureRect = TextureRect.new()
		heart.texture = HEART_EMPTY
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		heart.pivot_offset = HEART_FULL.get_size() / 2.0
		hearts_container.add_child( heart )
		_hearts.append( heart )
		_animate_pop_in( heart, ( _hearts.size() - 1 ) * 0.08 if intro else 0.0 )

func _new_heart_tween( heart : TextureRect ) -> Tween:
	if heart.has_meta( "tween" ):
		var old : Tween = heart.get_meta( "tween" )
		if old and old.is_valid():
			old.kill()
	heart.scale = Vector2.ONE
	heart.rotation = 0.0
	heart.self_modulate = Color.WHITE
	var tween : Tween = create_tween()
	heart.set_meta( "tween", tween )
	heart.set_meta( "busy", true )
	tween.finished.connect( _set_busy.bind( heart, false ) )
	return tween

func _set_busy( heart : TextureRect, value : bool ) -> void:
	if is_instance_valid( heart ):
		heart.set_meta( "busy", value )

func _set_heart( heart : TextureRect, texture : Texture2D, flash : bool ) -> void:
	if not is_instance_valid( heart ):
		return
	heart.texture = texture
	heart.self_modulate = FLASH if flash else Color.WHITE

func _animate_pop_in( heart : TextureRect, delay : float ) -> void:
	var tween : Tween = _new_heart_tween( heart )
	heart.scale = Vector2.ZERO
	tween.tween_interval( delay )
	tween.tween_property( heart, "scale", Vector2.ONE, 0.25 ).set_trans( Tween.TRANS_BACK ).set_ease( Tween.EASE_OUT )

func _animate_lose( heart : TextureRect, delay : float ) -> void:
	var tween : Tween = _new_heart_tween( heart )
	_set_heart( heart, HEART_FULL, false )
	tween.tween_interval( delay )
	tween.tween_callback( _set_heart.bind( heart, HEART_FULL, true ) )
	tween.tween_property( heart, "scale", Vector2( 1.7, 1.7 ), 0.07 )
	tween.tween_callback( _burst.bind( heart ) )
	tween.tween_callback( _set_heart.bind( heart, HEART_EMPTY, false ) )
	tween.tween_property( heart, "scale", Vector2( 0.55, 0.55 ), 0.06 )
	tween.tween_property( heart, "scale", Vector2.ONE, 0.25 ).set_trans( Tween.TRANS_BACK ).set_ease( Tween.EASE_OUT )

func _animate_gain( heart : TextureRect, delay : float ) -> void:
	var tween : Tween = _new_heart_tween( heart )
	tween.tween_interval( delay )
	tween.tween_callback( _set_heart.bind( heart, HEART_FULL, true ) )
	tween.tween_property( heart, "scale", Vector2( 1.7, 1.7 ), 0.1 ).from( Vector2( 0.3, 0.3 ) )
	tween.tween_callback( _set_heart.bind( heart, HEART_FULL, false ) )
	tween.tween_property( heart, "scale", Vector2.ONE, 0.25 ).set_trans( Tween.TRANS_BACK ).set_ease( Tween.EASE_OUT )

func _burst( heart : TextureRect ) -> void:
	if not is_instance_valid( heart ):
		return
	var origin : Vector2 = heart.global_position + HEART_FULL.get_size() / 2.0
	for i in 8:
		var particle : ColorRect = ColorRect.new()
		var pixel : float = 2.0 if randf() > 0.35 else 3.0
		particle.size = Vector2( pixel, pixel )
		particle.color = [ Color( 0.84, 0.16, 0.22 ), Color( 1.0, 0.55, 0.6 ), Color( 0.47, 0.08, 0.16 ) ].pick_random()
		particle.position = origin - particle.size / 2.0
		fx.add_child( particle )
		var target : Vector2 = particle.position + Vector2.from_angle( randf() * TAU ) * randf_range( 8.0, 24.0 ) + Vector2( 0, randf_range( 6.0, 14.0 ) )
		var tween : Tween = create_tween().set_parallel()
		tween.tween_property( particle, "position", target, 0.5 ).set_trans( Tween.TRANS_QUAD ).set_ease( Tween.EASE_OUT )
		tween.tween_property( particle, "modulate:a", 0.0, 0.5 )
		tween.chain().tween_callback( particle.queue_free )

func _shake_skull() -> void:
	if _skull_tween:
		_skull_tween.kill()
	skull_icon.rotation = 0.0
	skull_icon.self_modulate = Color( 1.0, 0.4, 0.4 )
	_skull_tween = create_tween()
	for angle in [ 0.4, -0.4, 0.3, -0.25, 0.1, 0.0 ]:
		_skull_tween.tween_property( skull_icon, "rotation", angle, 0.045 )
	_skull_tween.tween_property( skull_icon, "self_modulate", Color.WHITE, 0.15 )

# Full hearts beat one after another, like a pulse running through the bar
func _update_heartbeat( current : int, maximum : int ) -> void:
	if _beat_tween:
		_beat_tween.kill()
	if current <= 0:
		return
	var low : bool = float( current ) / maximum <= LOW_HEALTH_RATIO
	_beat_tween = create_tween().set_loops()
	_beat_tween.tween_interval( BEAT_PERIOD_LOW if low else BEAT_PERIOD )
	_beat_tween.tween_callback( _beat )

func _beat() -> void:
	for i in _hearts.size():
		var heart : TextureRect = _hearts[ i ]
		if heart.texture != HEART_FULL or heart.get_meta( "busy", false ):
			continue
		var tween : Tween = _new_heart_tween( heart )
		tween.tween_interval( i * 0.06 )
		tween.tween_property( heart, "scale", Vector2( 1.22, 1.22 ), 0.07 )
		tween.tween_property( heart, "scale", Vector2.ONE, 0.14 )

func _update_low_health_warning( current : int, maximum : int ) -> void:
	if _low_health_tween:
		_low_health_tween.kill()
	hearts_container.modulate = Color.WHITE
	if current <= 0 or float( current ) / maximum > LOW_HEALTH_RATIO:
		return
	_low_health_tween = create_tween().set_loops()
	_low_health_tween.tween_property( hearts_container, "modulate", Color( 1.0, 0.45, 0.45 ), 0.3 )
	_low_health_tween.tween_property( hearts_container, "modulate", Color.WHITE, 0.3 )

func _get_action_key_name( action : StringName ) -> String:
	for event in InputMap.action_get_events( action ):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return action
