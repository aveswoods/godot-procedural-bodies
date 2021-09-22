# Author: Ava Z. Beaver
# (MIT License)
# ---
# Link to Repository: https://github.com/azbeaver/godot-procedural-bodies
#
# This script provids a function for generating bodies whose meshes are defined by rotating a curve
# around an axis. Here are some rules about the function:
#
# - It is evaluated ONLY over [0, 1], i.e., between 0 and 1 inclusive
# - Its range over [0, 1] should also be [0, 1], it does not HAVE to be, but it is recommended
# - It does NOT have to be continuous, but there CANNOT be any "holes" in the function
# - It is passed as a FuncRef that takes one float input and returns one float
#
# This function is evaluated at a user-defined number of evenly distributed points (minimum 3). For
# each of these points, a "ring" is created around an axis with the distance equal to the value at
# that function's point. The number of evenly-spaced segments in the ring is also user-defined
# (minimum 3).
# Example: f(x) = x, rings = 3, segments = 4 -- this creates a square-based pyramid
#          f(x) = sin(2 * PI * x), rings = 9, segments = 9 -- this creates a sphere
#
# As of now, no validation is done. If you have any bugs or errors, make sure your function does
# not have any negative values, and that your number of rings/ segments >= 3
tool
extends EditorScript


# Specify the curve/function here
func _procedure_func(x):
	if x < 0.5:
		return x
	else:
		return 1 - x


# Creates and saves the body as a scene
func _run():
	# Make body
	var body = get_new_body(
		funcref(self, "_procedure_func"),	# Function to be rotated around the y axis
		Vector3(0.8, 1.0, 0.8),				# Scale of the mesh's axes
		5, 5								# Number of rings and ring segments, respectively
	)
	
	# Save body
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(body)
	if result == OK:
		var error = ResourceSaver.save("res://body.scn", packed_scene)
		if error == OK:
			print("Saved body")
		else:
			print("Error saving the scene. Code: " + str(error))

# Function that makes the body
# ----------------------------
# Modified from the tutorial in the ArrayMesh documentation
# Link: https://docs.godotengine.org/en/stable/tutorials/content/procedural_geometry/arraymesh.html
func get_new_body(radius_function: FuncRef, scale: Vector3 = Vector3(1.0, 1.0, 1.0), rings: int = 9, segments: int = 9):
	
	# Create MeshInstance
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = ArrayMesh.new()
	
	# SurfaceTool handles creation of mesh based on vertices
	var surface_tool = SurfaceTool.new()
	
	# -----------------
	# | Generate mesh |
	# -----------------
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Calculate radius values
	var radii = []
	for i in range(rings):
		radii.append(radius_function.call_func(float(i) / (rings - 1)))
	
	# Vertex indices
	var prevring = 0 # Index that starts the ring
	var thisring = 0
	var index = 0
	
	# Loop over rings
	for i in range(rings):
		# Used for UV coordinates
		var v = float(i) / (rings - 1)
		# Distance from y axis -- Comes from cylindrical coordinate system
		var rho = radii[i]
		# Base y coordinate for vertex
		var y = 1 - 2.0 * v
		
		# Loop over segments 
		for j in range(segments):
			# Used for UV coordinates
			var u = 1 - float(j) / segments
			# Base x and z coordinates for vertex
			var x = cos(2.0 * PI * u)
			var z = sin(2.0 * PI * u)
			
			# Scaled vertex based on radius and length
			var vertex = Vector3(
				scale.x * rho * x,
				scale.y * y,
				scale.z * rho * z
			)
			
			# Add vertex, UV, and normal to arrays
			surface_tool.add_uv(Vector2(u, v))
			surface_tool.add_vertex(vertex)
			index += 1
			
			# Create triangles based on indices.
			# Makes a quad (out of two triangles) whose "top-left" vertex is the previous
			# segment of the prevous ring, and whose "bottom-right vertex is this segment of this
			# ring.
			# Based on OpenGL triangle primitives. See this link for explanation:
			# http://www.dgp.toronto.edu/~ah/csc418/fall_2001/tut/ogl_draw.html
			if i > 0 and j > 0:
				# "Upper" triangle
				# ---- <- Previous ring
				# | /
				# |/   <- This ring
				surface_tool.add_index(prevring + j - 1)
				surface_tool.add_index(prevring + j)
				surface_tool.add_index(thisring + j - 1)
				
				# "Lower" triangle
				#   /| <- Previous ring
				#  / |
				# ---- <- This ring
				surface_tool.add_index(prevring + j)
				surface_tool.add_index(thisring + j)
				surface_tool.add_index(thisring + j - 1)
		
		# Connect the loop of triangles when a segment finishes
		if i > 0:
			# "Upper" triangle
			surface_tool.add_index(prevring + segments - 1)
			surface_tool.add_index(prevring)
			surface_tool.add_index(thisring + segments - 1)
			
			# "Lower" triangle
			surface_tool.add_index(prevring)
			surface_tool.add_index(thisring)
			surface_tool.add_index(thisring + segments - 1)
		
		# Reset vertex indices for next ring
		prevring = thisring
		thisring = index
	
	# Check for flat faces on the ends of the shape
	# The order that the indices are added comes from the winding order of the orientation
	# See this link for more information:
	# https://learnopengl.com/Advanced-OpenGL/Face-culling
	if radii[0] > 0.001:
		for i in range(segments - 2):
			surface_tool.add_index(i + 2)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(0)
	if radii[rings-1] > 0.001:
		for i in range(segments - 2):
			surface_tool.add_index((rings - 1) * segments)
			surface_tool.add_index((rings - 1) * segments + (i + 1))
			surface_tool.add_index((rings - 1) * segments + (i + 2))
	
	# Create mesh surface from mesh array
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	# ---------------------
	# | Finish Generating |
	# ---------------------
	
	# Now make the complete body
	var body = RigidBody.new()
	body.add_child(mesh_instance)
	mesh_instance.set_owner(body)
	var collision_shape = CollisionShape.new()
	collision_shape.shape = mesh_instance.mesh.create_convex_shape()
	body.add_child(collision_shape)
	collision_shape.set_owner(body)
	
	return body
