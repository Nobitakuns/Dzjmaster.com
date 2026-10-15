class_name FighterPortrait
extends TextureRect
## Crops one portrait from the 4 x 2 illustration atlas without modifying it.

const PORTRAITS: Texture2D = preload("res://assets/characters/portraits_atlas.png")
const TILE_SIZE := Vector2(443.5, 443.5)

var fighter_id: int = 0


func _ready() -> void:
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_region()


func set_fighter(index: int) -> void:
	fighter_id = clampi(index, 0, 7)
	_set_region()


func _set_region() -> void:
	var image := AtlasTexture.new()
	image.atlas = PORTRAITS
	image.region = Rect2(Vector2(float(fighter_id % 4), float(floori(float(fighter_id) / 4.0))) * TILE_SIZE, TILE_SIZE)
	texture = image
