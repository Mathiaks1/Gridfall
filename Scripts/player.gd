# player.gd
class_name Player # Umożliwia globalne odwoływanie się do typu Player

extends Node2D

# --- Sygnały do aktualizacji UI (HUD) ---
signal health_changed(current_hp, max_hp)
signal gold_changed(amount)
signal exp_changed(current_exp, exp_to_next_level)
signal level_up_available(level) # Sygnał, gdy gracz awansuje i może rozdzielić punkty

# --- Statystyki Gracza (bazowe, przed atrybutami) ---
var max_hp = 100
var current_hp = 100
var attack = 10
var defense = 5
var gold = 0
var experience = 0
var level = 1
var exp_required_for_level = {
	1: 0,   # Level 1 nie wymaga EXP, jest startowy
	2: 100,
	3: 250,
	4: 500,
	5: 800,
	6: 1200,
	7: 1700,
	8: 2300,
	9: 3000,
	10: 4000 # Możesz rozbudować to dalej
}

func _ready():
	# Emituj początkowe wartości do UI
	emit_health_changed()
	emit_gold_changed()
	emit_exp_changed()

func take_damage(amount: int):
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	print("Gracz otrzymal ", amount, " obrazen. HP: ", current_hp, "/", max_hp)
	emit_health_changed()
	if current_hp <= 0:
		# Game Over - obsługa w GridManager lub dedykowanym GameStateManager
		print("Gracz umarł! Koniec gry.")
		get_tree().call_group("game_manager", "player_died") # Wyslij sygnal do GridManager

func heal(amount: int):
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
	print("Gracz uleczony o ", amount, " HP. HP: ", current_hp, "/", max_hp)
	emit_health_changed()

func add_gold(amount: int):
	gold += amount
	print("Zdobyto ", amount, " zlota. Total: ", gold)
	emit_gold_changed()

func add_experience(amount: int):
	experience += amount
	print("Zdobyto ", amount, " EXP. Total: ", experience)
	emit_exp_changed()
	check_for_level_up()

func check_for_level_up():
	if level >= exp_required_for_level.size():
		return # Osiagnieto maksymalny poziom

	var next_level_exp = exp_required_for_level.get(level + 1, INF) # INF jesli nie ma nastepnego

	if experience >= next_level_exp:
		level += 1
		print("Gracz awansowal na poziom ", level, "!")
		max_hp += 10 # Przykladowe zwiekszenie statystyk bazowych
		attack += 2
		defense += 1
		current_hp = max_hp # Ulecz sie po awansie
		emit_health_changed()
		emit_exp_changed()
		emit_signal("level_up_available", level) # Emituj sygnał do UI, aby otworzyć ekran awansu

# Funkcje pomocnicze do emitowania sygnałów (aby uniknąć powtarzania kodu)
func emit_health_changed():
	emit_signal("health_changed", current_hp, max_hp)

func emit_gold_changed():
	emit_signal("gold_changed", gold)

func emit_exp_changed():
	var exp_to_next = exp_required_for_level.get(level + 1, 0)
	# Jesli gracz jest na maks. poziomie, ustaw exp_to_next na 0
	if level >= exp_required_for_level.size():
		exp_to_next = 0
	emit_signal("exp_changed", experience, exp_to_next)

# TODO: Metody do zarządzania ekwipunkiem, atrybutami, itp. (w przyszłości)
