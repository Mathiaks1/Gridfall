# battle_manager.gd
extends Node2D

class_name BattleManager

@export var player_hp_bar: ProgressBar
@export var player_hp_label: Label
@export var monster_hp_bar: ProgressBar
@export var monster_hp_label: Label
@export var battle_log: RichTextLabel
@export var attack_button: Button
@export var item_button: Button
@export var run_button: Button
@export var action_buttons_container: VBoxContainer # Kontener na przyciski akcji

var player_node: Player
var current_monster: Monster
var previous_grid_coords: Vector2i # Koordynaty pola, z którego weszliśmy do walki
var previous_tile_instance: Tile # Referencja do instancji Tile

enum BattleState { PLAYER_TURN, ENEMY_TURN, BATTLE_END }
var current_state = BattleState.PLAYER_TURN

func _ready():
	# Upewnij się, że wszystkie węzły UI zostały prawidłowo przypięte w inspektorze
	if not player_hp_bar or not player_hp_label or not monster_hp_bar or not monster_hp_label or not battle_log or not attack_button or not item_button or not run_button or not action_buttons_container:
		printerr("Błąd: Elementy UI w BattleManager nie są poprawnie przypięte!")
		return

	attack_button.pressed.connect(_on_attack_button_pressed)
	item_button.pressed.connect(_on_item_button_pressed)
	run_button.pressed.connect(_on_run_button_pressed)

	# Znajdź instancję gracza (będzie istniała przez całą grę)
	player_node = get_tree().get_first_node_in_group("player") as Player
	if not player_node:
		printerr("Błąd: Nie znaleziono węzła gracza w grupie 'player'!")
		get_tree().change_scene_to_file("res://Scenes/Game.tscn") # Powrót do mapy lochu awaryjnie
		return

	# Inicjalizuj statystyki UI
	update_player_ui()
	update_monster_ui()
	battle_log.text = "Rozpoczyna sie walka z " + current_monster.monster_name + "!"

	start_battle_turn()

func initialize_battle(monster_instance: Monster, coords: Vector2i, tile: Tile):
	# Ta funkcja będzie wywoływana przez GridManager przed przełączeniem sceny
	current_monster = monster_instance
	previous_grid_coords = coords
	previous_tile_instance = tile # Zachowaj referencję, aby móc usunąć potwora po walce

	# Przenieś potwora do sceny walki
	if current_monster.get_parent():
		current_monster.get_parent().remove_child(current_monster)
	add_child(current_monster)
	current_monster.position = $MonsterPosition.position # Ustaw pozycję potwora

	# Ukryj przyciski akcji na początku, dopóki nie będzie tura gracza
	set_player_actions_enabled(false)

func start_battle_turn():
	if player_node.current_hp <= 0:
		end_battle(false) # Gracz przegral
		return
	if current_monster.current_hp <= 0:
		end_battle(true) # Potwor przegral
		return

	match current_state:
		BattleState.PLAYER_TURN:
			set_player_actions_enabled(true)
			battle_log.append_text("\nTwoja tura. Wybierz akcje:")
		BattleState.ENEMY_TURN:
			set_player_actions_enabled(false)
			battle_log.append_text("\nTura " + current_monster.monster_name + ".")
			await get_tree().create_timer(1.0).timeout # Poczekaj na animację/rozmyślanie
			perform_monster_attack()
		BattleState.BATTLE_END:
			pass # Obsluga zakonczenia walki

func set_player_actions_enabled(enabled: bool):
	for button in action_buttons_container.get_children():
		if button is Button:
			button.disabled = not enabled

func _on_attack_button_pressed():
	if current_state != BattleState.PLAYER_TURN: return
	set_player_actions_enabled(false)
	perform_player_attack()

func _on_item_button_pressed():
	if current_state != BattleState.PLAYER_TURN: return
	set_player_actions_enabled(false)
	battle_log.append_text("\n[TODO: Otworz menu przedmiotow]")
	# Tymczasowo: ulecz gracza
	player_node.heal(20)
	await get_tree().create_timer(0.5).timeout
	next_turn()

func _on_run_button_pressed():
	if current_state != BattleState.PLAYER_TURN: return
	set_player_actions_enabled(false)
	var run_chance = 50 # % szansy na ucieczkę
	if randi() % 100 < run_chance:
		battle_log.append_text("\nUdalo Ci sie uciec!")
		end_battle(true, true) # Drugi parametr true oznacza ucieczke
	else:
		battle_log.append_text("\nNie udalo Ci sie uciec!")
		await get_tree().create_timer(1.0).timeout
		next_turn()

func perform_player_attack():
	var damage_dealt = max(0, player_node.attack - current_monster.get_defense_value())
	var monster_died = current_monster.take_damage(damage_dealt)
	battle_log.append_text("\nZadales " + str(damage_dealt) + " obrazen " + current_monster.monster_name + ".")
	update_monster_ui()

	if monster_died:
		end_battle(true)
	else:
		await get_tree().create_timer(1.0).timeout # Poczekaj na odczytanie logu
		next_turn()

func perform_monster_attack():
	var damage_taken = max(0, current_monster.get_attack_value() - player_node.defense)
	player_node.take_damage(damage_taken)
	battle_log.append_text("\n" + current_monster.monster_name + " zadal Ci " + str(damage_taken) + " obrazen.")
	update_player_ui()

	if player_node.current_hp <= 0:
		end_battle(false)
	else:
		await get_tree().create_timer(1.0).timeout
		next_turn()

func next_turn():
	if current_monster.current_hp <= 0:
		end_battle(true) # Potwor pokonany
		return
	if player_node.current_hp <= 0:
		end_battle(false) # Gracz pokonany
		return

	# Przełącz turę
	if current_state == BattleState.PLAYER_TURN:
		current_state = BattleState.ENEMY_TURN
	else:
		current_state = BattleState.PLAYER_TURN

	start_battle_turn()

func update_player_ui():
	player_hp_bar.max_value = player_node.max_hp
	player_hp_bar.value = player_node.current_hp
	player_hp_label.text = "HP: %d/%d" % [player_node.current_hp, player_node.max_hp]

func update_monster_ui():
	if current_monster:
		monster_hp_bar.max_value = current_monster.max_hp
		monster_hp_bar.value = current_monster.current_hp
		monster_hp_label.text = "HP: %d/%d" % [current_monster.current_hp, current_monster.max_hp]
	else:
		monster_hp_bar.value = 0
		monster_hp_label.text = "HP: --/--"

func end_battle(player_won: bool, fled: bool = false):
	current_state = BattleState.BATTLE_END
	set_player_actions_enabled(false)
	await get_tree().create_timer(1.5).timeout # Krótka pauza

	if player_won and not fled:
		battle_log.append_text("\nWygrales walke!")
		player_node.add_experience(current_monster.exp_drop)
		player_node.add_gold(current_monster.gold_drop)

		# Usuń potwora po walce
		if current_monster:
			current_monster.queue_free()

		# Wróć do sceny gry
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")
		# Po powrocie do GridManager, musimy powiadomić go, aby odsłonił pole
		# i zaktualizował stan Tile, aby nie było już miną.
		# To będzie wymagało modyfikacji GridManager.gd

	elif fled:
		battle_log.append_text("\nUciekles z walki!")
		# Tutaj możesz dodać karę za ucieczkę, np. player_node.take_damage(10)
		if current_monster:
			current_monster.queue_free() # Ucieczka zazwyczaj usuwa potwora
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")

	else: # Gracz przegrał
		battle_log.append_text("\nZostales pokonany!")
		get_tree().call_group("game_manager", "player_died") # Sygnalizuj GridManager, że gracz umarł
		# Możesz wyświetlić Game Over UI tutaj lub pozwolić GridManagerowi to zrobić
		# Na razie zmieniamy scenę tylko w przypadku zwycięstwa/ucieczki
		# W przypadku porażki GridManager powinien już obsłużyć game over
		get_tree().change_scene_to_file("res://Scenes/Game.tscn") # Może wrócić do mapy, żeby pokazać miny.
