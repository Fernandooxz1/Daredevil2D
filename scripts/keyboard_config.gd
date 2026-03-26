extends Control

# Mapeo de acciones del proyecto con sus nombres visibles
const ACTION_NAMES: Dictionary = {
	"jump": "Saltar",
	"run": "Correr",
	"left": "Izquierda",
	"right": "Derecha",
	"crouch": "Agacharse",
	"attack": "Atacar",
	"hability1": "Patada",
	"blokear": "Bloquear",
	"Cambiar Arma": "Cambiar Arma",
	"Pausa": "Pausa",
	"interact": "Interactuar",
}

var waiting_for_input: bool = false
var action_to_remap: String = ""
var button_to_update: Button = null

@onready var key_list_container = $VBoxContainer/ScrollContainer/KeyListContainer
@onready var status_label = $VBoxContainer/StatusLabel

func _ready() -> void:
	_build_key_list()
	status_label.text = ""

func _build_key_list() -> void:
	# Limpiar lista existente
	for child in key_list_container.get_children():
		child.queue_free()

	for action in ACTION_NAMES:
		var display_name = ACTION_NAMES[action]
		var current_key = _get_action_key_name(action)

		# Contenedor horizontal para cada acción
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Label con el nombre de la acción
		var label = Label.new()
		label.text = display_name
		label.custom_minimum_size = Vector2(200, 0)
		label.add_theme_font_size_override("font_size", 22)
		hbox.add_child(label)

		# Botón que muestra la tecla actual y permite remapear
		var btn = Button.new()
		btn.text = current_key
		btn.custom_minimum_size = Vector2(200, 40)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_remap_button_pressed.bind(action, btn))
		hbox.add_child(btn)

		key_list_container.add_child(hbox)

func _get_action_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var key_text = events[0].as_text()
		# Quitar el sufijo "(Physical)" si existe
		key_text = key_text.replace(" (Physical)", "")
		return key_text
	return "Sin asignar"

func _on_remap_button_pressed(action: String, btn: Button) -> void:
	waiting_for_input = true
	action_to_remap = action
	button_to_update = btn
	btn.text = "Presioná una tecla..."
	status_label.text = "Esperando tecla para: " + ACTION_NAMES[action]

func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return

	# Aceptar teclas y botones del mouse
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			# Verificar que no esté siendo usada por otra acción
			var conflict = _find_conflict(event)
			if conflict != "":
				status_label.text = "¡Conflicto! Ya usada por: " + ACTION_NAMES.get(conflict, conflict)
				waiting_for_input = false
				button_to_update.text = _get_action_key_name(action_to_remap)
				return

			# Remapear la acción
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)

			var remap_text = event.as_text().replace(" (Physical)", "")
			button_to_update.text = remap_text
			status_label.text = ACTION_NAMES[action_to_remap] + " → " + remap_text
			waiting_for_input = false
			get_viewport().set_input_as_handled()

func _find_conflict(event: InputEvent) -> String:
	for action in ACTION_NAMES:
		if action == action_to_remap:
			continue
		var events = InputMap.action_get_events(action)
		for existing_event in events:
			if existing_event is InputEventKey and event is InputEventKey:
				if existing_event.physical_keycode == event.physical_keycode:
					return action
			elif existing_event is InputEventMouseButton and event is InputEventMouseButton:
				if existing_event.button_index == event.button_index:
					return action
	return ""

# Botón "Restaurar por defecto"
func _on_reset_pressed() -> void:
	InputMap.load_from_project_settings()
	_build_key_list()
	status_label.text = "Controles restaurados a los valores por defecto"

# Botón "Atrás"
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")

# Sonidos de hover
func _on_button_hover() -> void:
	$VBoxContainer/MoveSound.play()
func _on_button_select() -> void:
	$VBoxContainer/SelectSound.play()
