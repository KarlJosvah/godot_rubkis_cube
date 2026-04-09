extends Node3D

@export var animation_speed := 0.3

@onready var camera_pivot: Node3D = get_parent().get_node("Camera_Pivot")
@onready var sfx_button: AudioStreamPlayer = $SFX/SFX_Button;

var is_rotating := false
var _move_history: Array[Dictionary] = []
var _is_recording_history: bool = true

func _rotate_layer(face_normal: Vector3, angle: float, include_middle: bool = false, only_middle: bool = false, whole_cube: bool = false) -> void:
	if is_rotating:
		return
	is_rotating = true
	
	self.sfx_button.play();
	if _is_recording_history:
		_move_history.append({
			"face_normal": face_normal,
			"angle": angle,
			"include_middle": include_middle,
			"only_middle": only_middle,
			"whole_cube": whole_cube
		})

	
	# Create a temporary pivot at the center of the cube
	var pivot := Node3D.new()
	add_child(pivot)
	pivot.global_position = Vector3.ZERO
	
	# Determine which axis (X, Y, or Z) to filter pieces by
	var axis_idx := 0
	if abs(face_normal.y) > 0.5: axis_idx = 1
	elif abs(face_normal.z) > 0.5: axis_idx = 2
	
	var pieces: Array[Node3D] = []
	for child in get_children():
		if child is MeshInstance3D:
			var global_val = child.global_position[axis_idx]
			
			var is_match := false
			if only_middle:
				is_match = abs(global_val) < 0.1
			elif include_middle:
				# Small moves rotate the outer layer and the middle slice
				if face_normal[axis_idx] > 0.5: 
					is_match = global_val > -0.1
				else: 
					is_match = global_val < 0.1
			else:
				# Standard move selects only the outer layer
				if face_normal[axis_idx] > 0.5: 
					is_match = global_val > 0.1
				else: 
					is_match = global_val < -0.1
				
			if whole_cube:
				is_match = true
				
			if is_match:
				pieces.append(child)
	
	# Parent pieces to pivot, preserving their global transforms
	for piece in pieces:
		piece.reparent(pivot, true)
	
	# Animate the rotation using a Tween
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var target_quat := (pivot.quaternion * Quaternion(face_normal.normalized(), angle)).normalized()
	tween.tween_property(pivot, "quaternion", target_quat, animation_speed)
	
	await tween.finished
	
	# Reparent pieces back to the cube, baking the new transform
	for piece in pieces:
		piece.reparent(self, true)
	
	pivot.queue_free()
	is_rotating = false

func _get_camera_relative_normal(camera_dir: Vector3) -> Vector3:
	if abs(camera_dir.x) > abs(camera_dir.z):
		return Vector3.RIGHT if camera_dir.x > 0 else Vector3.LEFT
	else:
		return Vector3.BACK if camera_dir.z > 0 else Vector3.FORWARD

# ----------[ ACTIONS ]--------------------------------------------------------------------

func scramble(hard_scramble : bool = false, steps: int = 20) -> void:
	if is_rotating:
		return
	
	var moves : Array[Callable] = [];
	
	if hard_scramble:
		moves = [
			move_U, move_U_p, move_U_s, move_U_sp,
			move_D, move_D_p, move_D_s, move_D_sp,
			move_L, move_L_p, move_L_s, move_L_sp,
			move_R, move_R_p, move_R_s, move_R_sp,
			move_F, move_F_p, move_F_s, move_F_sp,
			move_B, move_B_p, move_B_s, move_B_sp,
			move_M, move_M_p
		]
	else:
		moves = [
			move_U, move_U_p, move_D, move_D_p,
			move_L, move_L_p, move_R, move_R_p,
			move_F, move_F_p, move_B, move_B_p
		]
	
	var original_speed := animation_speed
	animation_speed = 0.05
	_is_recording_history = false
	
	for i in range(steps):
		var move_func = moves.pick_random()
		await move_func.call()
		
	_is_recording_history = true
	animation_speed = original_speed
	_move_history = []

func undo() -> void:
	if is_rotating or _move_history.is_empty():
		return
	
	var last_move = _move_history.pop_back()
	
	_is_recording_history = false
	await _rotate_layer(
		last_move.face_normal, 
		-last_move.angle, 
		last_move.include_middle, 
		last_move.only_middle,
		last_move.get("whole_cube", false)
	)
	_is_recording_history = true


# ----------[ MOVES: STANDARD ]------------------------------------------------------------

func move_U() -> void: await _rotate_layer(Vector3.UP, -PI / 2.0)
func move_U_p() -> void: await _rotate_layer(Vector3.UP, PI / 2.0)
func move_D() -> void: await _rotate_layer(Vector3.DOWN, -PI / 2.0)
func move_D_p() -> void: await _rotate_layer(Vector3.DOWN, PI / 2.0)

func move_R() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0)
func move_R_p() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0)

func move_L() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0)
func move_L_p() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0)

func move_F() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, -PI / 2.0)
func move_F_p() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, PI / 2.0)

func move_B() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, -PI / 2.0)
func move_B_p() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, PI / 2.0)

# ----------[ MOVES: SMALL ]---------------------------------------------------------------

func move_U_s() -> void: await _rotate_layer(Vector3.UP, -PI / 2.0, true)
func move_U_sp() -> void: await _rotate_layer(Vector3.UP, PI / 2.0, true)
func move_D_s() -> void: await _rotate_layer(Vector3.DOWN, -PI / 2.0, true)
func move_D_sp() -> void: await _rotate_layer(Vector3.DOWN, PI / 2.0, true)

func move_R_s() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0, true)
func move_R_sp() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0, true)

func move_L_s() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0, true)
func move_L_sp() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0, true)

func move_F_s() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, -PI / 2.0, true)
func move_F_sp() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, PI / 2.0, true)

func move_B_s() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, -PI / 2.0, true)
func move_B_sp() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, PI / 2.0, true)

# ----------[ MOVES: SLICES ]--------------------------------------------------------------

func move_M() -> void:
	# M follows L's direction
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0, false, true)

func move_M_p() -> void:
	var normal := _get_camera_relative_normal(-camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0, false, true)

func move_E() -> void:
	# E follows D's direction
	await _rotate_layer(Vector3.DOWN, -PI / 2.0, false, true)

func move_E_p() -> void:
	await _rotate_layer(Vector3.DOWN, PI / 2.0, false, true)

func move_S() -> void:
	# S follows F's direction
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, -PI / 2.0, false, true)

func move_S_p() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.z)
	await _rotate_layer(normal, PI / 2.0, false, true)

func move_x() -> void:
	# x follows R's direction
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, -PI / 2.0, false, false, true)

func move_x_p() -> void:
	var normal := _get_camera_relative_normal(camera_pivot.global_transform.basis.x)
	await _rotate_layer(normal, PI / 2.0, false, false, true)
