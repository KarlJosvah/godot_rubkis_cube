extends Node3D;

@onready var camera_pivot: Node3D = $Camera_Pivot;
@onready var spring_arm_3d: SpringArm3D = $Camera_Pivot/SpringArm3D;
@onready var rubik_s_cube: Node3D = $rubik_s_cube;

@export_group("Settings")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25;
@export var orbit_keyboard_speed := 10.5;
@export var snap_duration := 0.15;
@export var zoom_min := 1.0;
@export var zoom_max := 6.0;

@export_subgroup("Inversion")
@export var invert_horizontal := false;
@export var invert_vertical := true;

var camera_input_direction := Vector2.ZERO;
var snap_tween: Tween;

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;

# ----------[ EVENT ]----------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("right_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	if event.is_action_pressed("zoom_in"):
		self.zoom(+1);
	if event.is_action_pressed("zoom_out"):
		self.zoom(-1);
	self.handle_arrow_snap(event);
	self.cube_input();

func _unhandled_input(event: InputEvent) -> void:
	self.catch_camera_rotation(event);

func _physics_process(delta: float) -> void:
	self.handle_continuous_orbit(delta);
	self.rotate_camera(delta);

# ----------[ CAMERA ]----------------------------------------------------------------------

func handle_arrow_snap(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return;
	if event.shift_pressed or Input.is_key_pressed(KEY_SHIFT):
		return;

	var key_event := event as InputEventKey;
	var key: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode;
	if key == KEY_LEFT:
		self.snap_camera(-PI / 2.0, 0.0);
	elif key == KEY_RIGHT:
		self.snap_camera(PI / 2.0, 0.0);
	elif key == KEY_UP:
		self.snap_camera(0.0, -PI / 2.0);
	elif key == KEY_DOWN:
		self.snap_camera(0.0, PI / 2.0);

func snap_camera(delta_y: float, delta_x: float) -> void:
	if snap_tween and snap_tween.is_running():
		snap_tween.kill();

	var step := PI / 2.0;
	var target_y: float = round((self.camera_pivot.rotation.y + delta_y) / step) * step;
	var target_x: float = clampf(round((self.camera_pivot.rotation.x + delta_x) / step) * step, -PI / 2.0, PI / 2.0);

	snap_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
	snap_tween.parallel().tween_property(self.camera_pivot, "rotation:y", target_y, snap_duration);
	snap_tween.parallel().tween_property(self.camera_pivot, "rotation:x", target_x, snap_duration);

func handle_continuous_orbit(delta: float) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		return;

	var orbit_dir := Vector2.ZERO;
	# Shift + WASD
	if Input.is_key_pressed(KEY_D): orbit_dir.x -= 1.0;
	if Input.is_key_pressed(KEY_A): orbit_dir.x += 1.0;
	if Input.is_key_pressed(KEY_S): orbit_dir.y -= 1.0;
	if Input.is_key_pressed(KEY_W): orbit_dir.y += 1.0;

	# Shift + Arrow Keys
	if Input.is_key_pressed(KEY_RIGHT): orbit_dir.x -= 1.0;
	if Input.is_key_pressed(KEY_LEFT): orbit_dir.x += 1.0;
	if Input.is_key_pressed(KEY_DOWN): orbit_dir.y -= 1.0;
	if Input.is_key_pressed(KEY_UP): orbit_dir.y += 1.0;

	if orbit_dir != Vector2.ZERO:
		if snap_tween and snap_tween.is_running():
			snap_tween.kill();
		orbit_dir = orbit_dir.normalized();
		self.camera_pivot.rotation.y += orbit_dir.x * self.orbit_keyboard_speed * delta;
		self.camera_pivot.rotation.x += orbit_dir.y * self.orbit_keyboard_speed * delta;
		self.camera_pivot.rotation.x = clamp(self.camera_pivot.rotation.x, -PI / 2.0, PI / 2.0);

func catch_camera_rotation(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	);
	
	if is_camera_motion:
		self.camera_input_direction = event.screen_relative * mouse_sensitivity;

func rotate_camera(delta: float) -> void:
	# Handle Horizontal Rotation (Y-axis)
	var horizontal_factor := -1.0 if not invert_horizontal else 1.0;
	self.camera_pivot.rotation.y += self.camera_input_direction.x * delta * horizontal_factor;
	
	# Handle Vertical Rotation (X-axis)
	var vertical_factor := 1.0 if not invert_vertical else -1.0;
	self.camera_pivot.rotation.x += self.camera_input_direction.y * delta * vertical_factor;
	self.camera_pivot.rotation.x = clamp(self.camera_pivot.rotation.x, -PI / 2.0, PI / 2.0);
	
	self.camera_input_direction = Vector2.ZERO;

func zoom(direction: int) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return;
	self.spring_arm_3d.spring_length += (-1 * self.mouse_sensitivity * direction);
	self.spring_arm_3d.spring_length = clamp(self.spring_arm_3d.spring_length, self.zoom_min, self.zoom_max);

# ----------[ CUBE ]----------------------------------------------------------------------

func cube_input() -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		return

	var is_small: bool = Input.is_action_pressed("move_small") or Input.is_key_pressed(KEY_CTRL)

	# U / U' (O / W)
	if Input.is_action_just_pressed("move_U"):
		if is_small: self.rubik_s_cube.move_U_s()
		else: self.rubik_s_cube.move_U()
	if Input.is_action_just_pressed("move_U_p"):
		if is_small: self.rubik_s_cube.move_U_sp()
		else: self.rubik_s_cube.move_U_p()

	# D / D' (S / L)
	if Input.is_action_just_pressed("move_D"):
		if is_small: self.rubik_s_cube.move_D_s()
		else: self.rubik_s_cube.move_D()
	if Input.is_action_just_pressed("move_D_p"):
		if is_small: self.rubik_s_cube.move_D_sp()
		else: self.rubik_s_cube.move_D_p()

	# R / R' (P / ;)
	if Input.is_action_just_pressed("move_R"):
		if is_small: self.rubik_s_cube.move_R_s()
		else: self.rubik_s_cube.move_R()
	if Input.is_action_just_pressed("move_R_p"):
		if is_small: self.rubik_s_cube.move_R_sp()
		else: self.rubik_s_cube.move_R_p()

	# L / L' (A / Q)
	if Input.is_action_just_pressed("move_L"):
		if is_small: self.rubik_s_cube.move_L_s()
		else: self.rubik_s_cube.move_L()
	if Input.is_action_just_pressed("move_L_p"):
		if is_small: self.rubik_s_cube.move_L_sp()
		else: self.rubik_s_cube.move_L_p()

	# F / F' (K / D)
	if Input.is_action_just_pressed("move_F"):
		if is_small: self.rubik_s_cube.move_F_s()
		else: self.rubik_s_cube.move_F()
	if Input.is_action_just_pressed("move_F_p"):
		if is_small: self.rubik_s_cube.move_F_sp()
		else: self.rubik_s_cube.move_F_p()

	# B / B' (E / I)
	if Input.is_action_just_pressed("move_B"):
		if is_small: self.rubik_s_cube.move_B_s()
		else: self.rubik_s_cube.move_B()
	if Input.is_action_just_pressed("move_B_p"):
		if is_small: self.rubik_s_cube.move_B_sp()
		else: self.rubik_s_cube.move_B_p()

	# Slices & Rotations (no small moves)
	# M / M' (F / J)
	if Input.is_action_just_pressed("move_M"):
		self.rubik_s_cube.move_M()
	if Input.is_action_just_pressed("move_M_p"):
		self.rubik_s_cube.move_M_p()

	# E / E' (V / N)
	if Input.is_action_just_pressed("move_E"):
		self.rubik_s_cube.move_E()
	if Input.is_action_just_pressed("move_E_p"):
		self.rubik_s_cube.move_E_p()

	# S / S' (M / C)
	if Input.is_action_just_pressed("move_S"):
		self.rubik_s_cube.move_S()
	if Input.is_action_just_pressed("move_S_p"):
		self.rubik_s_cube.move_S_p()

	# x / x' (U / R)
	if Input.is_action_just_pressed("move_x"):
		self.rubik_s_cube.move_x()
	if Input.is_action_just_pressed("move_x_p"):
		self.rubik_s_cube.move_x_p()

	# y / y' (Y / T)
	if Input.is_action_just_pressed("move_y"):
		self.rubik_s_cube.move_y()
	if Input.is_action_just_pressed("move_y_p"):
		self.rubik_s_cube.move_y_p()

	# z / z' (H / G)
	if Input.is_action_just_pressed("move_z"):
		self.rubik_s_cube.move_z()
	if Input.is_action_just_pressed("move_z_p"):
		self.rubik_s_cube.move_z_p()

	# Undo (Ctrl+Z)
	if Input.is_action_just_pressed("undo") or Input.is_action_just_pressed("ui_undo"):
		self.rubik_s_cube.undo()

	# Scramble (Space)
	if Input.is_action_just_pressed("scramble") or Input.is_action_just_pressed("ui_accept"):
		if is_small:
			self.rubik_s_cube.scramble(true)
		else:
			self.rubik_s_cube.scramble()
