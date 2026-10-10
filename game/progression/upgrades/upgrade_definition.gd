extends Resource

@export var title: String = ""
@export_multiline var description: String = ""
@export_enum("sword_damage", "max_health", "attack_range", "move_speed") var stat: String = "sword_damage"
@export var amount: float = 0.0
@export var multiplier: float = 1.0
