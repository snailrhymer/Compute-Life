extends Node
# Based on https://gist.github.com/winston-yallow/aab20fa437bfa3dd80bfb0ed6605d28e

# The 'active' grid size.
# The actual grid is padded with an extra cell on each side, so that neighbour
# indices can be found quickly without worrying about going out of bounds.
# Each component must be divisible by the corresponding component of group_size.
@export var grid_size := Vector2i(1024, 1024)

# Must match the local sizes defined in the shader.
@export var group_size := Vector2i(4, 4)

@export_range(0.0, 1.0) var random_proportion := 0.5

var rd : RenderingDevice
var shader : RID
var read_buffer: RID
var write_buffer: RID
var uniform_set: RID
var pipeline: RID

var read_data: PackedByteArray
var write_data: PackedByteArray

var running := false

func _ready() -> void:
	_prepare()

func _process(_delta: float) -> void:
	if running:
		execute()

func _prepare() -> void:
	# Load in shader.
	var shader_file: RDShaderFile = load("res://life_compute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	rd = RenderingServer.create_local_rendering_device()
	shader = rd.shader_create_from_spirv(shader_spirv)
	
	# Initialise the byte array the shader will read from.
	read_data = PackedByteArray()
	# 4 bytes per float.
	read_data.resize((grid_size.x + 2) * (grid_size.y + 2) * 4)
	
	# Create storage buffer for the input array.
	read_buffer = rd.storage_buffer_create(read_data.size(), read_data)
	var read_uniform := RDUniform.new()
	read_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	read_uniform.binding = 0 # Matches shader code.
	read_uniform.add_id(read_buffer)
	
	# Initialise the byte array the shader will write to.
	write_data = PackedByteArray()
	write_data.resize(read_data.size())
	
	# Create storage buffer for the output array.
	write_buffer = rd.storage_buffer_create(write_data.size(), write_data)
	var write_uniform := RDUniform.new()
	write_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	write_uniform.binding = 1
	write_uniform.add_id(write_buffer)
	
	# Create buffer for sending grid size data to array.
	var size_data_bytes := PackedByteArray(PackedInt32Array([grid_size.x + 2, grid_size.y + 2]).to_byte_array())
	var size_data_buffer = rd.storage_buffer_create(8, size_data_bytes)
	var size_data_uniform := RDUniform.new()
	size_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	size_data_uniform.binding = 2
	size_data_uniform.add_id(size_data_buffer)
	
	# Create a set for the uniforms.
	uniform_set = rd.uniform_set_create([read_uniform, write_uniform, size_data_uniform], shader, 0)
	
	pipeline = rd.compute_pipeline_create(shader)


func execute() -> void:
	
	rd.buffer_update(read_buffer, 0, read_data.size(), read_data)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	# Here, don't use the +2 padding, since we want the shader to only work on the inner 'active' grid.
	rd.compute_list_dispatch(compute_list, grid_size.x/group_size.x, grid_size.y/group_size.y, 1)
	rd.compute_list_end()
	
	# Submit to the GPU and wait for data
	rd.submit()
	rd.sync()
	
	# Get data from the buffer and put it into the input array for the next iteration.
	read_data = rd.buffer_get_data(write_buffer)
	# Send data to TextureRect for displaying.
	_update_display(read_data)


func randomise_data():
	var new_data = PackedFloat32Array()
	new_data.resize((grid_size.x + 2) * (grid_size.y + 2))
	for i in grid_size.x:
		for j in grid_size.y:
			new_data[i + 1 + (j + 1)*grid_size.x] = float(randf() < random_proportion)
	read_data = new_data.to_byte_array()
	_update_display(read_data)


func _update_display(with_data: PackedByteArray):
	get_node("../TextureManager").set_data(with_data)

