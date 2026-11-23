class_name ControlsPanel extends PanelContainer

signal closed

# [ label, [ input actions ] ]
const ROWS : Array = [
	[ "MOVER", [ "left", "right" ] ],
	[ "PULAR", [ "jump" ] ],
	[ "ATACAR", [ "attack" ] ],
	[ "PAUSAR", [ "pause" ] ],
]
const KEY_NAMES : Dictionary = {
	"Escape": "ESC", "Space": "ESPAÇO", "Left": "←", "Right": "→", "Up": "↑", "Down": "↓",
	"Shift": "SHIFT", "Ctrl": "CTRL", "Enter": "ENTER",
}

@onready var rows_container : VBoxContainer = %RowsContainer
@onready var back_button : Button = %BackButton

func _ready() -> void:
	for row in ROWS:
		rows_container.add_child( _build_row( row[ 0 ], row[ 1 ] ) )
	back_button.pressed.connect( close )

func open() -> void:
	show()
	back_button.grab_focus()

func close() -> void:
	hide()
	closed.emit()

func _unhandled_input( event: InputEvent ) -> void:
	if visible and event.is_action_pressed( "ui_cancel" ):
		get_viewport().set_input_as_handled()
		close()

func _build_row( label_text : String, actions : Array ) -> HBoxContainer:
	var row : HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override( "separation", 6 )
	var label : Label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child( label )
	for action in actions:
		row.add_child( _build_keycap( _get_key_name( action ) ) )
	return row

func _build_keycap( key_text : String ) -> PanelContainer:
	var cap : PanelContainer = PanelContainer.new()
	var style : StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color( 0.91, 0.88, 0.8 )
	style.border_color = Color( 0.45, 0.4, 0.36 )
	style.border_width_bottom = 3
	style.set_content_margin_all( 4 )
	style.content_margin_bottom = 2
	style.anti_aliasing = false
	cap.add_theme_stylebox_override( "panel", style )
	cap.custom_minimum_size = Vector2( 22, 0 )
	var label : Label = Label.new()
	label.text = key_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override( "font_color", Color( 0.063, 0.04, 0.094 ) )
	cap.add_child( label )
	return cap

func _get_key_name( action : StringName ) -> String:
	for event in InputMap.action_get_events( action ):
		if event is InputEventKey:
			var code : int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			var key_name : String = OS.get_keycode_string( code )
			return KEY_NAMES.get( key_name, key_name.to_upper() )
	return "?"
