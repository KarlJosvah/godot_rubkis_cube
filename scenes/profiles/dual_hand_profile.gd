extends Node

@export_group("Settings")
@export var orbit_keyboard_speed: float = 10.5
@export var snap_duration: float = 0.15

@export_group("Inversion")
@export var invert_keyboard_horizontal: bool = true
@export var invert_keyboard_vertical: bool = true

var main: Node3D
var cube: Node3D
var camera_pivot: Node3D
var snap_tween: Tween

func setup(p_main: Node3D, p_cube: Node3D, p_camera_pivot: Node3D) -> void:
	self.main = p_main
	self.cube = p_cube
	self.camera_pivot = p_camera_pivot

func _physics_process(delta: float) -> void:
	self.handle_continuous_orbit(delta)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.is_echo():
		return

	# Handle 90-degree Arrow Snapping (when Shift is not pressed)
	if not (key_event.shift_pressed or Input.is_key_pressed(KEY_SHIFT)):
		if self.handle_arrow_snap(key_event):
			return

	# When Shift is pressed, cube moves are disabled so Shift+WASD orbits camera
	if key_event.shift_pressed or Input.is_key_pressed(KEY_SHIFT):
		return

	self.handle_cube_input(key_event)

func handle_arrow_snap(event: InputEventKey) -> bool:
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	var h_step: float = PI / 2.0 if invert_keyboard_horizontal else -PI / 2.0
	var v_step: float = PI / 2.0 if invert_keyboard_vertical else -PI / 2.0

	if key == KEY_LEFT:
		self.snap_camera(h_step, 0.0)
		return true
	elif key == KEY_RIGHT:
		self.snap_camera(-h_step, 0.0)
		return true
	elif key == KEY_UP:
		self.snap_camera(0.0, v_step)
		return true
	elif key == KEY_DOWN:
		self.snap_camera(0.0, -v_step)
		return true
	return false

func snap_camera(delta_y: float, delta_x: float) -> void:
	if not is_instance_valid(self.camera_pivot):
		return
	if snap_tween and snap_tween.is_running():
		snap_tween.kill()

	var step := PI / 2.0
	var target_y: float = round((self.camera_pivot.rotation.y + delta_y) / step) * step
	var target_x: float = clampf(round((self.camera_pivot.rotation.x + delta_x) / step) * step, -PI / 2.0, PI / 2.0)

	snap_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	snap_tween.parallel().tween_property(self.camera_pivot, "rotation:y", target_y, snap_duration)
	snap_tween.parallel().tween_property(self.camera_pivot, "rotation:x", target_x, snap_duration)

func handle_continuous_orbit(delta: float) -> void:
	if not is_instance_valid(self.camera_pivot):
		return
	if not Input.is_key_pressed(KEY_SHIFT):
		return

	var orbit_dir := Vector2.ZERO
	# Shift + WASD
	if Input.is_key_pressed(KEY_A): orbit_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): orbit_dir.x += 1.0
	if Input.is_key_pressed(KEY_W): orbit_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S): orbit_dir.y += 1.0

	# Shift + Arrow Keys
	if Input.is_key_pressed(KEY_LEFT): orbit_dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): orbit_dir.x += 1.0
	if Input.is_key_pressed(KEY_UP): orbit_dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN): orbit_dir.y += 1.0

	if orbit_dir != Vector2.ZERO:
		if snap_tween and snap_tween.is_running():
			snap_tween.kill()
		orbit_dir = orbit_dir.normalized()
		var h_factor: float = -1.0 if invert_keyboard_horizontal else 1.0
		var v_factor: float = -1.0 if invert_keyboard_vertical else 1.0
		self.camera_pivot.rotation.y += orbit_dir.x * self.orbit_keyboard_speed * delta * h_factor
		self.camera_pivot.rotation.x += orbit_dir.y * self.orbit_keyboard_speed * delta * v_factor
		self.camera_pivot.rotation.x = clampf(self.camera_pivot.rotation.x, -PI / 2.0, PI / 2.0)

func handle_cube_input(event: InputEventKey) -> void:
	if not is_instance_valid(self.cube):
		return

	var is_small: bool = event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	match key:
		# U / U' (O / W)
		KEY_O:
			if is_small: self.cube.move_U_s()
			else: self.cube.move_U()
		KEY_W:
			if is_small: self.cube.move_U_sp()
			else: self.cube.move_U_p()

		# D / D' (S / L)
		KEY_S:
			if is_small: self.cube.move_D_s()
			else: self.cube.move_D()
		KEY_L:
			if is_small: self.cube.move_D_sp()
			else: self.cube.move_D_p()

		# R / R' (P / ;)
		KEY_P:
			if is_small: self.cube.move_R_s()
			else: self.cube.move_R()
		KEY_SEMICOLON:
			if is_small: self.cube.move_R_sp()
			else: self.cube.move_R_p()

		# L / L' (A / Q)
		KEY_A:
			if is_small: self.cube.move_L_s()
			else: self.cube.move_L()
		KEY_Q:
			if is_small: self.cube.move_L_sp()
			else: self.cube.move_L_p()

		# F / F' (K / D)
		KEY_K:
			if is_small: self.cube.move_F_s()
			else: self.cube.move_F()
		KEY_D:
			if is_small: self.cube.move_F_sp()
			else: self.cube.move_F_p()

		# B / B' (E / I)
		KEY_E:
			if is_small: self.cube.move_B_s()
			else: self.cube.move_B()
		KEY_I:
			if is_small: self.cube.move_B_sp()
			else: self.cube.move_B_p()

		# Slices (no small moves)
		KEY_F: self.cube.move_M()
		KEY_J: self.cube.move_M_p()
		KEY_V: self.cube.move_E()
		KEY_N: self.cube.move_E_p()
		KEY_M: self.cube.move_S()
		KEY_C: self.cube.move_S_p()

		# Rotations (no small moves)
		KEY_U: self.cube.move_x()
		KEY_R: self.cube.move_x_p()
		KEY_T: self.cube.move_y_p()
		KEY_Y: self.cube.move_y()
		KEY_G: self.cube.move_z_p()
		KEY_H: self.cube.move_z()

		# Undo (Ctrl+Z)
		KEY_Z:
			if is_small:
				self.cube.undo()

		# Scramble (Space, Ctrl for hard scramble)
		KEY_SPACE:
			if is_small:
				self.cube.scramble(true)
			else:
				self.cube.scramble()
