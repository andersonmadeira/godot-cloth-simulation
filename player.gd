extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5

const BALL = preload("res://ball.tscn")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var movement_direction := Vector3.ZERO

@export var max_zoom := 2.0
@export var min_zoom := 30.0
@export var zoom_factor := 1.0
@export var lookaround_speed := 0.005
@export var lookup_speed := 0.005
@export var player_rotation_speed := 10.0
@export var walking_speed := 4.5
@export var running_speed := 8.0
@export var world: Node3D

@onready var camera_arm_pivot: Node3D = $CameraArmPivot
@onready var camera_arm: SpringArm3D = $CameraArmPivot/CameraArm
@onready var camera: Camera3D = $CameraArmPivot/CameraArm/Camera3D
@onready var mesh: MeshInstance3D = $BodyMesh
@onready var orientation: Node3D = $Orientation

var controlling_camera := false
# TODO: The way this var is used deserves improvment, we might have to remove it?
var mouse_button_down := 0
var is_running := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event is InputEventMouseButton and \
		(event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			on_camera_event(event.pressed, event.button_index)
	if event is InputEventMouseMotion and is_controlling_camera():
		on_camera_move(event.relative)
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera_arm.spring_length = clamp(camera_arm.spring_length - zoom_factor, max_zoom, min_zoom)
	if event.is_pressed() and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera_arm.spring_length = clamp(camera_arm.spring_length + zoom_factor, max_zoom, min_zoom)

func on_camera_event(pressed: bool, button_index: int) -> void:
	controlling_camera = pressed
	
	print('controlling_camera: ', controlling_camera)

	if pressed:
		mouse_button_down = button_index
	else:
		mouse_button_down = 0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_camera_move(mouse_relative_input: Vector2) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
	camera_arm_pivot.rotate_y(-mouse_relative_input.x * lookup_speed)
	camera_arm.rotate_x(-mouse_relative_input.y * lookaround_speed)
	camera_arm.rotation.x = clamp(camera_arm.rotation.x, deg_to_rad(-80), deg_to_rad(-10))

func is_controlling_camera() -> bool:
	return controlling_camera and mouse_button_down

func _process(delta: float) -> void:
	_handle_input()
	_update_mesh_rotation(delta)
	
func _handle_input() -> void:
	if Input.is_action_just_pressed("spawn_ball"):
		var ball: Ball = BALL.instantiate()
		var force = -mesh.transform.basis.z * 30 + Vector3(0, 1, 0)
		world.add_child(ball)
		ball.global_position = global_position + Vector3(0, 1.5, 0)
		ball.apply_force(force)
		
	# we only let the player start running if they are on the floor
	# but allow them to keep running (maintain speed) if in the air but jumped while running
	var next_is_running = Input.is_action_pressed("run")
	if next_is_running != is_running and is_on_floor():
		is_running = next_is_running
	
	# Jump start
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var movement_input := _get_keyboard_input()
	
	movement_direction = (camera_arm_pivot.transform.basis * Vector3(movement_input.x, 0, movement_input.y)).normalized()

func _get_keyboard_input() -> Vector2:
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	return keyboard_input

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	
func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var speed = running_speed if is_running else walking_speed
	
	if movement_direction:
		velocity.x = movement_direction.x * speed
		velocity.z = movement_direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
func _update_mesh_rotation(delta: float) -> void:
	var new_basis: Basis
	var q_to : Quaternion
	var direction := movement_direction
	
	if controlling_camera:
		if mouse_button_down == MOUSE_BUTTON_RIGHT:
			q_to = camera_arm_pivot.basis.get_rotation_quaternion()
			var q_from := mesh.transform.basis.get_rotation_quaternion()
			new_basis = Basis(q_from.slerp(q_to, delta * player_rotation_speed))
	elif direction:
		var direction_basis = Basis.looking_at(direction)
		q_to = direction_basis.get_rotation_quaternion()
		var q_from := mesh.transform.basis.get_rotation_quaternion()
		new_basis = Basis(q_from.slerp(q_to, delta * player_rotation_speed))
		
	if new_basis:
		mesh.basis = new_basis
		orientation.basis = new_basis
