extends TextureRect

@onready var grid_size = get_node("../LifeCompute").grid_size

func _ready():
	var image = Image.create(grid_size.x + 2, grid_size.y + 2, false, Image.FORMAT_RF)
	texture = ImageTexture.create_from_image(image)


func set_data(data : PackedByteArray):
	var image = Image.create_from_data(grid_size.x + 2, grid_size.y + 2, false, Image.FORMAT_RF, data)
	texture.update(image)
