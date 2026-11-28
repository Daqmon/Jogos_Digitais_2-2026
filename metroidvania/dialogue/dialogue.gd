extends CanvasLayer

@onready var portrait: TextureRect = $Portrait
@onready var dialogue_text: RichTextLabel = $DialogueText

func _ready() -> void:
	hide()
	# The UI tells the manager: "I exist, send data to me!"
	DialogueManager.dialogue_ui = self

# We will call this function from the Manager
func show_dialogue(character_portrait: Texture2D, text: String) -> void:
	portrait.texture = character_portrait
	dialogue_text.text = text
	show()
