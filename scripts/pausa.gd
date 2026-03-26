extends CanvasLayer

# --- Constantes para remapeo de teclado ---
const ACTION_NAMES: Dictionary = {
	"jump": "Saltar",
	"run": "Correr",
	"left": "Izquierda",
	"right": "Derecha",
	"crouch": "Agacharse",
	"attack": "Atacar",
	"blokear": "Bloquear",
	"Cambiar Arma": "Cambiar Arma",
	"Pausa": "Pausa",
	"interact": "Interactuar",
}

var waiting_for_input: bool = false
var action_to_remap: String = ""
var button_to_update: Button = null

# --- Pausar con Esc ---
func _physics_process(_delta):
	if Input.is_action_just_pressed("Pausa"):
		if waiting_for_input:
			# Cancelar remapeo si se presiona Pausa mientras espera tecla
			waiting_for_input = false
			if button_to_update:
				button_to_update.text = _get_action_key_name(action_to_remap)
			return

		get_tree().paused = not get_tree().paused

		if get_tree().paused:
			_show_main_menu()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			_hide_all_panels()
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _show_main_menu():
	$TextureRect.visible = true
	$Menu1.visible = true
	$options.visible = false
	$KeyboardPanel.visible = false
	$SoundPanel.visible = false

func _hide_all_panels():
	$TextureRect.visible = false
	$Menu1.visible = false
	$options.visible = false
	$KeyboardPanel.visible = false
	$SoundPanel.visible = false

# --- Menu1: Resume ---
func _on_button_pressed() -> void:
	get_tree().paused = false
	_hide_all_panels()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# --- Menu1: Options ---
func _on_button_2_pressed() -> void:
	$Menu1.visible = false
	$options.visible = true

# --- Menu1: Quit ---
func _on_button_3_pressed() -> void:
	get_tree().quit()

# --- Options: Sound ---
func _on_button_4_pressed() -> void:
	$options.visible = false
	$SoundPanel.visible = true
	_update_volume_label()

# --- Options: Keyboard ---
func _on_button_5_pressed() -> void:
	$options.visible = false
	$KeyboardPanel.visible = true
	_build_key_list()

# --- Options: Back ---
func _on_button_6_pressed() -> void:
	$options.visible = false
	$KeyboardPanel.visible = false
	$SoundPanel.visible = false
	$Menu1.visible = true

# ============================================
# KEYBOARD REMAPPING (inline en pausa)
# ============================================

func _build_key_list():
	var container = $KeyboardPanel/ScrollContainer/KeyListContainer
	for child in container.get_children():
		child.queue_free()

	for action in ACTION_NAMES:
		var display_name = ACTION_NAMES[action]
		var current_key = _get_action_key_name(action)

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		label.text = display_name
		label.custom_minimum_size = Vector2(200, 0)
		label.add_theme_font_size_override("font_size", 22)
		hbox.add_child(label)

		var btn = Button.new()
		btn.text = current_key
		btn.custom_minimum_size = Vector2(220, 40)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_remap_button_pressed.bind(action, btn))
		hbox.add_child(btn)

		container.add_child(hbox)

func _get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0].as_text()
	return "Sin asignar"

func _on_remap_button_pressed(action: String, btn: Button) -> void:
	waiting_for_input = true
	action_to_remap = action
	button_to_update = btn
	btn.text = "Presioná una tecla..."
	$KeyboardPanel/StatusLabel.text = "Esperando tecla para: " + ACTION_NAMES[action]

func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return

	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			# Verificar conflictos
			var conflict = _find_conflict(event)
			if conflict != "":
				$KeyboardPanel/StatusLabel.text = "¡Conflicto! Ya usada por: " + ACTION_NAMES.get(conflict, conflict)
				waiting_for_input = false
				button_to_update.text = _get_action_key_name(action_to_remap)
				return

			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)

			button_to_update.text = event.as_text()
			$KeyboardPanel/StatusLabel.text = ACTION_NAMES[action_to_remap] + " → " + event.as_text()
			waiting_for_input = false
			get_viewport().set_input_as_handled()

func _find_conflict(event: InputEvent) -> String:
	for action in ACTION_NAMES:
		if action == action_to_remap:
			continue
		for existing_event in InputMap.action_get_events(action):
			if existing_event is InputEventKey and event is InputEventKey:
				if existing_event.physical_keycode == event.physical_keycode:
					return action
			elif existing_event is InputEventMouseButton and event is InputEventMouseButton:
				if existing_event.button_index == event.button_index:
					return action
	return ""

func _on_reset_keys_pressed() -> void:
	InputMap.load_from_project_settings()
	_build_key_list()
	$KeyboardPanel/StatusLabel.text = "Controles restaurados"

func _on_keyboard_back_pressed() -> void:
	$KeyboardPanel.visible = false
	$options.visible = true
	waiting_for_input = false

# ============================================
# SOUND SETTINGS
# ============================================

func _update_volume_label():
	var volume_db = AudioServer.get_bus_volume_db(0)
	var volume_pct = int(db_to_linear(volume_db) * 100)
	$SoundPanel/VolumeLabel.text = "Volumen: " + str(volume_pct) + "%"
	$SoundPanel/VolumeSlider.value = volume_pct

func _on_volume_slider_changed(value: float) -> void:
	var linear_val = value / 100.0
	if linear_val <= 0.01:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(linear_val))
	$SoundPanel/VolumeLabel.text = "Volumen: " + str(int(value)) + "%"

func _on_sound_back_pressed() -> void:
	$SoundPanel.visible = false
	$options.visible = true
