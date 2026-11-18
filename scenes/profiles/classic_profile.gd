extends Node

var main: Node3D
var cube: Node3D
var camera_pivot: Node3D

func setup(p_main: Node3D, p_cube: Node3D, p_camera_pivot: Node3D) -> void:
	self.main = p_main
	self.cube = p_cube
	self.camera_pivot = p_camera_pivot

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.is_echo():
		return

	self.handle_cube_input(key_event)

func handle_cube_input(event: InputEventKey) -> void:
	if not is_instance_valid(self.cube):
		return

	var is_prime: bool = event.shift_pressed or Input.is_key_pressed(KEY_SHIFT)
	var is_small: bool = event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

	match key:
		# U (W)
		KEY_W:
			if is_prime:
				if is_small: self.cube.move_U_sp()
				else: self.cube.move_U_p()
			elif is_small: self.cube.move_U_s()
			else: self.cube.move_U()

		# D (S)
		KEY_S:
			if is_prime:
				if is_small: self.cube.move_D_sp()
				else: self.cube.move_D_p()
			elif is_small: self.cube.move_D_s()
			else: self.cube.move_D()

		# R (D)
		KEY_D:
			if is_prime:
				if is_small: self.cube.move_R_sp()
				else: self.cube.move_R_p()
			elif is_small: self.cube.move_R_s()
			else: self.cube.move_R()

		# L (A)
		KEY_A:
			if is_prime:
				if is_small: self.cube.move_L_sp()
				else: self.cube.move_L_p()
			elif is_small: self.cube.move_L_s()
			else: self.cube.move_L()

		# F (Q)
		KEY_Q:
			if is_prime:
				if is_small: self.cube.move_F_sp()
				else: self.cube.move_F_p()
			elif is_small: self.cube.move_F_s()
			else: self.cube.move_F()

		# B (E)
		KEY_E:
			if is_prime:
				if is_small: self.cube.move_B_sp()
				else: self.cube.move_B_p()
			elif is_small: self.cube.move_B_s()
			else: self.cube.move_B()

		# M (X)
		KEY_X:
			if is_prime: self.cube.move_M_p()
			else: self.cube.move_M()

		# E (C)
		KEY_C:
			if is_prime: self.cube.move_E_p()
			else: self.cube.move_E()

		# S (V)
		KEY_V:
			if is_prime: self.cube.move_S_p()
			else: self.cube.move_S()

		# x (F)
		KEY_F:
			if is_prime: self.cube.move_x_p()
			else: self.cube.move_x()

		# Undo (Ctrl+Z)
		KEY_Z:
			if is_small:
				self.cube.undo()

		# Scramble (Space, Shift for hard scramble)
		KEY_SPACE:
			if is_prime:
				self.cube.scramble(true)
			else:
				self.cube.scramble()
