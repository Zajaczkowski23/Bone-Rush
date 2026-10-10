extends Control

signal upgrade_selected(upgrade: Resource)

var _choices: Array[Resource] = []
var _accepting_selection: bool = false

@onready var title_label: Label = %Title
@onready var choices_container: VBoxContainer = %Choices


func _ready() -> void:
	for index in range(choices_container.get_child_count()):
		choices_container.get_child(index).pressed.connect(_select_upgrade.bind(index))


func show_choices(level: int, choices: Array[Resource]) -> void:
	_choices = choices
	title_label.text = "LEVEL %d" % level
	for index in range(choices_container.get_child_count()):
		var button := choices_container.get_child(index) as Button
		button.text = "%s\n%s" % [choices[index].title, choices[index].description]
		button.disabled = false
	_accepting_selection = true
	show()
	choices_container.get_child(0).call_deferred("grab_focus")


func _select_upgrade(index: int) -> void:
	if not visible or not _accepting_selection or index < 0 or index >= _choices.size():
		return
	_accepting_selection = false
	for button in choices_container.get_children():
		button.disabled = true
	hide()
	upgrade_selected.emit(_choices[index])
