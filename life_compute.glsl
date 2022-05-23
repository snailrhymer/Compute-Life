#[compute]

#version 450


layout(local_size_x = 4, local_size_y = 4) in;

// Set & bindings to match those defined in GDScript.
layout(set = 0, binding = 0, std430) restrict buffer FloatBufferIn {
  float data[];
}
buffer_in;

layout(set = 0, binding = 1, std430) restrict buffer FloatBufferOut {
  float data[];
}
buffer_out;

layout(set = 0, binding = 2, std430) restrict buffer SizeDataBuffer {
  int width;
  int height;
}
size_data;

void get_neighbours_lazy(out int[8] neighbour_indices, in int index) {
  // Return the eight neighbour indices of the given index.
  // Don't worry about whether the indices are out of bounds.
  neighbour_indices = int[8]( \
      index - 1 - size_data.width, index - size_data.width, index + 1 - size_data.width, \
      index - 1,                                            index + 1,                   \
      index - 1 + size_data.width, index + size_data.width, index + 1 + size_data.width);
}

void main() {
    // Use gl_GlobalInvocationID to get the array index for this invocation.
    // Offset by 1 in each direction to allow lazy finding of neighbour indices.
    int index = int((gl_GlobalInvocationID.x + 1) + (gl_GlobalInvocationID.y + 1) * size_data.width);
    
    int[8] neighbour_indices;
    neighbour_indices = int[8](-1, -1, -1, -1, -1, -1, -1, -1);
    get_neighbours_lazy(neighbour_indices, index);
    
    // Calculate number of living neighbours.
    float neighbour_life = 0.0;
    neighbour_life += buffer_in.data[neighbour_indices[0]];
    neighbour_life += buffer_in.data[neighbour_indices[1]];
    neighbour_life += buffer_in.data[neighbour_indices[2]];
    neighbour_life += buffer_in.data[neighbour_indices[3]];
    neighbour_life += buffer_in.data[neighbour_indices[4]];
    neighbour_life += buffer_in.data[neighbour_indices[5]];
    neighbour_life += buffer_in.data[neighbour_indices[6]];
    neighbour_life += buffer_in.data[neighbour_indices[7]];

    // Cell comes to life with exactly three living neighbours. Stays alive with two or three living neighbours.
    // Write new state to output buffer.
    buffer_out.data[index] = float((neighbour_life == 2.0)) * buffer_in.data[index] + float((neighbour_life == 3.0)) * 1.0;

}


