extends Node3D;

@onready var camera_pivot: Node3D = $Camera_Pivot;
@onready var spring_arm_3d: SpringArm3D = $Camera_Pivot/SpringArm3D;
@onready var rubik_s_cube: Node3D = $rubik_s_cube;

@export_group("Settings")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25;
@export var zoom_min := 1.0;
@export var zoom_max := 6.0;

@export_subgroup("Inversion")
@export var invert_horizontal := false;
@export var invert_vertical := true;

var camera_input_direction := Vector2.ZERO;

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
	self.cube_input();

func _unhandled_input(event: InputEvent) -> void:
	self.catch_camera_rotation(event);

func _physics_process(delta: float) -> void:
	self.rotate_camera(delta);

# ----------[ CAMERA ]----------------------------------------------------------------------

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
	if Input.is_action_just_pressed("move_U"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_U_sp()
			else:
				self.rubik_s_cube.move_U_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_U_s()
		else: self.rubik_s_cube.move_U()
	
	if Input.is_action_just_pressed("move_D"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_D_sp()
			else:
				self.rubik_s_cube.move_D_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_D_s()
		else: self.rubik_s_cube.move_D()
	
	if Input.is_action_just_pressed("move_R"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_R_sp()
			else:
				self.rubik_s_cube.move_R_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_R_s()
		else: self.rubik_s_cube.move_R()
	
	if Input.is_action_just_pressed("move_L"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_L_sp()
			else:
				self.rubik_s_cube.move_L_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_L_s()
		else: self.rubik_s_cube.move_L()
	
	if Input.is_action_just_pressed("move_F"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_F_sp()
			else:
				self.rubik_s_cube.move_F_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_F_s()
		else: self.rubik_s_cube.move_F()
	
	if Input.is_action_just_pressed("move_B"):
		if Input.is_action_pressed("move_prime"):
			if Input.is_action_pressed("move_small"):
				self.rubik_s_cube.move_B_sp()
			else:
				self.rubik_s_cube.move_B_p()
		elif Input.is_action_pressed("move_small"):
			self.rubik_s_cube.move_B_s()
		else: self.rubik_s_cube.move_B()
		
	if Input.is_action_just_pressed("move_M"):
		if Input.is_action_pressed("move_prime"):
			self.rubik_s_cube.move_M_p()
		else:
			self.rubik_s_cube.move_M()
			
	if Input.is_action_just_pressed("ui_undo"):
		self.rubik_s_cube.undo()
		
	if Input.is_action_just_pressed("ui_accept"):
		if Input.is_action_pressed("move_prime"):
			self.rubik_s_cube.scramble(true)
		else:
			self.rubik_s_cube.scramble()
