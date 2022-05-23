extends TextureRect

@onready var grid_size = get_node("../LifeCompute").grid_size

func _ready():
	var image = Image.new()
	image.create(grid_size.x + 2, grid_size.y + 2, false, Image.FORMAT_RF)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image)
	texture = image_texture


func set_data(data : PackedByteArray):
	var image = texture.get_image()
	image.create_from_data(grid_size.x + 2, grid_size.y + 2, false, Image.FORMAT_RF, data)
	texture.update(image)
