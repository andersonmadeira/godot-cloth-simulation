extends RigidBody3D
class_name Ball

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(randf(), randf(), randf())
	mesh.set_surface_override_material(0, material)
	
	particles.finished.connect(_on_particles_finished)

func explode() -> void:
	mesh.visible = false
	
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.1
	particle_mesh.height = 0.2
	particle_mesh.material = mesh.get_surface_override_material(0)
	particles.draw_pass_1 = particle_mesh
	
	particles.emitting = true

func _on_particles_finished() -> void:
	queue_free()
