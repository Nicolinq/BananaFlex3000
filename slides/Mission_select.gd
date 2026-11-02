extends MPFSlide

# Mission_select slide
# Shown when the player qualifies a mission and enters bd_lock.
# The player cycles through available missions with the flipper buttons
# and confirms selection by pressing the launch button.
#
# MPF events received:
#   - mission_select_start  : slide is shown (via slide_player in mission_manager)
#   - s_flipper_left_button_active  : cycle left
#   - s_flipper_right_button_active : cycle right
#   - s_launch_button_active        : confirm selection
#
# MPF events posted:
#   - select_maintenance_mission
#   - select_shipping_mission

# ── Available missions (only those not completed) ─────────────────────────
# Populated dynamically from pv_* player variables when the slide becomes active.
var _missions: Array[String] = []
var _current_index: int = 0

# Labels that are updated when selection changes
@onready var _title_label: Label = $VBoxContainer/TitleLabel
@onready var _mission_label: Label = $VBoxContainer/MissionName
@onready var _desc_label: Label = $VBoxContainer/MissionDesc
@onready var _hint_label: Label = $VBoxContainer/HintLabel
@onready var _arrow_left: Label = $VBoxContainer/ArrowRow/ArrowLeft
@onready var _arrow_right: Label = $VBoxContainer/ArrowRow/ArrowRight

# Mission display data ---------------------------------------------------------
const MISSION_DATA: Dictionary = {
	"maintenance_mission": {
		"label": "MAINTENANCE",
		"desc": "Répare l'usine !\nTouche 100 switchs en 120s",
		"completed_var": "pv_maintenance_mission_completed",
	},
	"shipping_mission": {
		"label": "LIVRAISON",
		"desc": "Envoie 3 camions de bananes !\nMur + Rampe × 3 en 90s",
		"completed_var": "pv_shipping_mission_completed",
	},
}

func _ready() -> void:
	# Register MPF switch event handlers
	MPF.server.add_event_handler("s_flipper_left_button_active", _on_left)
	MPF.server.add_event_handler("s_flipper_right_button_active", _on_right)
	MPF.server.add_event_handler("s_launch_button_active", _on_confirm)

	# Build list of non-completed missions
	_build_mission_list()

	if _missions.is_empty():
		# Safety: should not happen — mission_manager guards this
		MPF.server.send_event("select_maintenance_mission")
		return

	_current_index = 0
	_update_display()

func _exit_tree() -> void:
	MPF.server.remove_event_handler("s_flipper_left_button_active", _on_left)
	MPF.server.remove_event_handler("s_flipper_right_button_active", _on_right)
	MPF.server.remove_event_handler("s_launch_button_active", _on_confirm)

# ── Build selectable mission list ────────────────────────────────────────────
func _build_mission_list() -> void:
	_missions.clear()
	for mission_key in MISSION_DATA.keys():
		var completed_var: String = MISSION_DATA[mission_key]["completed_var"]
		# Read the player variable (0 = not completed, 1 = completed)
		var val = MPF.game.player.get(completed_var) if MPF.game and MPF.game.player else 0
		if val == 0:
			_missions.append(mission_key)

# ── Navigation ────────────────────────────────────────────────────────────────
func _on_left(_payload: Dictionary) -> void:
	if _missions.size() <= 1:
		return
	_current_index = (_current_index - 1 + _missions.size()) % _missions.size()
	_update_display()

func _on_right(_payload: Dictionary) -> void:
	if _missions.size() <= 1:
		return
	_current_index = (_current_index + 1) % _missions.size()
	_update_display()

func _on_confirm(_payload: Dictionary) -> void:
	if _missions.is_empty():
		return
	var selected: String = _missions[_current_index]
	MPF.server.send_event("select_%s" % selected)

# ── Display update ────────────────────────────────────────────────────────────
func _update_display() -> void:
	if _missions.is_empty():
		_mission_label.text = "—"
		_desc_label.text = ""
		_hint_label.text = ""
		_arrow_left.visible = false
		_arrow_right.visible = false
		return

	var key: String = _missions[_current_index]
	var data: Dictionary = MISSION_DATA[key]

	_mission_label.text = data["label"]
	_desc_label.text = data["desc"]

	var has_multiple: bool = _missions.size() > 1
	_arrow_left.visible = has_multiple
	_arrow_right.visible = has_multiple

	if has_multiple:
		_hint_label.text = "◀ Flipper  |  LANCE pour confirmer  |  Flipper ▶"
	else:
		_hint_label.text = "LANCE pour confirmer"
