extends Node3D;

enum ControlProfile { DUAL_HAND, CLASSIC }

@export_group("Control Profile")
@export var active_profile: ControlProfile = ControlProfile.DUAL_HAND;
@export var toggle_profile_key: Key = KEY_F1;

@export_group("Settings")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25;
@export var zoom_min := 1.0;
@export var zoom_max := 6.0;

@export_group("Inversion")
@export_subgroup("Mouse")
@export var invert_mouse_horizontal := false;
@export var invert_mouse_vertical := true;

@onready var camera_pivot: Node3D = $Camera_Pivot;
@onready var spring_arm_3d: SpringArm3D = $Camera_Pivot/SpringArm3D;
@onready var rubik_s_cube: Node3D = $rubik_s_cube;

@onready var input_profiles: Node = $InputProfiles;
@onready var dual_hand_profile: Node = $InputProfiles/DualHandProfile;
@onready var classic_profile: Node = $InputProfiles/ClassicProfile;
@onready var profile_label: Label = get_node_or_null("HUD/ProfileLabel");

var camera_input_direction := Vector2.ZERO;

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	if is_instance_valid(dual_hand_profile):
		dual_hand_profile.setup(self, rubik_s_cube, camera_pivot);
	if is_instance_valid(classic_profile):
		classic_profile.setup(self, rubik_s_cube, camera_pivot);
	self.set_profile(active_profile);

# ----------[ PROFILE SWITCHING ]----------------------------------------------------------

func set_profile(profile: ControlProfile) -> void:
	active_profile = profile;
	if is_instance_valid(dual_hand_profile) and is_instance_valid(classic_profile):
		match active_profile:
			ControlProfile.DUAL_HAND:
				dual_hand_profile.process_mode = Node.PROCESS_MODE_INHERIT;
				classic_profile.process_mode = Node.PROCESS_MODE_DISABLED;
			ControlProfile.CLASSIC:
				dual_hand_profile.process_mode = Node.PROCESS_MODE_DISABLED;
				classic_profile.process_mode = Node.PROCESS_MODE_INHERIT;
	self._update_profile_ui();

func toggle_profile() -> void:
	var next_profile := ControlProfile.CLASSIC if active_profile == ControlProfile.DUAL_HAND else ControlProfile.DUAL_HAND;
	self.set_profile(next_profile);

func _update_profile_ui() -> void:
	if is_instance_valid(profile_label):
		var profile_name := "Dual-Hand (WASD + OKL;)" if active_profile == ControlProfile.DUAL_HAND else "Classic (Single-Hand + Mouse)";
		profile_label.text = "Profile: %s [F1 to switch]" % profile_name;

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

	# Check for profile toggle key
	if event is InputEventKey:
		var key_event := event as InputEventKey;
		if key_event.pressed and not key_event.is_echo():
			var key: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode;
			if key == toggle_profile_key:
				self.toggle_profile();

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
	var horizontal_factor := -1.0 if not invert_mouse_horizontal else 1.0;
	self.camera_pivot.rotation.y += self.camera_input_direction.x * delta * horizontal_factor;
	
	# Handle Vertical Rotation (X-axis)
	var vertical_factor := 1.0 if not invert_mouse_vertical else -1.0;
	self.camera_pivot.rotation.x += self.camera_input_direction.y * delta * vertical_factor;
	self.camera_pivot.rotation.x = clamp(self.camera_pivot.rotation.x, -PI / 2.0, PI / 2.0);
	
	self.camera_input_direction = Vector2.ZERO;

func zoom(direction: int) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return;
	self.spring_arm_3d.spring_length += (-1 * self.mouse_sensitivity * direction);
	self.spring_arm_3d.spring_length = clamp(self.spring_arm_3d.spring_length, self.zoom_min, self.zoom_max);
