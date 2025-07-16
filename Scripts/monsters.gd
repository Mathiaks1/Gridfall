# monster.gd
class_name Monster # Umożliwia globalne odwoływanie się do typu Monster

extends Node2D

@export var monster_name = "Goblin"
@export var max_hp = 30
var current_hp = 30
@export var attack = 8
@export var defense = 2
@export var gold_drop = 15
@export var exp_drop = 20

func _ready():
	current_hp = max_hp

func take_damage(amount: int):
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	print(monster_name, " otrzymal ", amount, " obrazen. HP: ", current_hp, "/", max_hp)
	if current_hp <= 0:
		return true # Potwór umarł
	return false # Potwór żyje

func get_attack_value():
	return attack

func get_defense_value():
	return defense

func get_drop_values():
	return {"gold": gold_drop, "exp": exp_drop}
