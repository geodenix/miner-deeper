extends Node2D

const BASE_W: float = 720.0
const TILE: float = 52.0
const COLS: int = 12
const ROWS: int = 180
const GRID_X: float = 48.0
const TOP_H: float = 170.0
const BOTTOM_H: float = 390.0
const SURFACE_ROW: int = 1
const META_SAVE: String = "user://meta_v06.json"
const MINE_SAVE: String = "user://mine_v06.json"

enum GameState { MENU, PLAY, SHOP, QUESTS, PAUSE, GAME_OVER }

var state: GameState = GameState.MENU
var rng := RandomNumberGenerator.new()

var world: Array = []
var hazards: Dictionary = {}
var enemies: Array = []
var boss: Dictionary = {}
var boss_defeated: bool = false
var mine_loaded: bool = false

var player: Vector2i = Vector2i(5, SURFACE_ROW)
var facing: Vector2i = Vector2i.DOWN
var hp: int = 100
var coins: int = 0
var pick_level: int = 1
var bag_level: int = 1
var armor_level: int = 1
var tnt: int = 2
var max_depth: int = 0
var lifetime_ore: int = 0
var bosses_killed: int = 0
var quest_index: int = 0
var turn_count: int = 0

# v0.7 run systems
var run_max_depth: int = 0
var run_ore: int = 0
var run_kills: int = 0
var combo: int = 0
var combo_grace: int = 0
var frenzy_charge: int = 0
var frenzy_turns: int = 0
var potions: int = 1
var contract_type: String = "ore"
var contract_target: int = 20
var contract_reward: int = 150
var contract_paid: bool = false

var inventory: Dictionary = {
	"coal": 0,
	"iron": 0,
	"gold": 0,
	"diamond": 0,
	"ruby": 0
}

var message: String = ""
var message_time: float = 0.0

func _ready() -> void:
	rng.randomize()
	load_meta()
	mine_loaded = load_mine()
	if not mine_loaded:
		generate_mine()
	state = GameState.MENU
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_all()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_all()
		get_tree().quit()

func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
	queue_redraw()

func screen_h() -> float:
	return get_viewport_rect().size.y

func control_top() -> float:
	return screen_h() - BOTTOM_H

func mine_center_y() -> float:
	return (TOP_H + control_top()) * 0.5

func left_rect() -> Rect2:
	return Rect2(28, control_top() + 178, 126, 126)

func right_rect() -> Rect2:
	return Rect2(302, control_top() + 178, 126, 126)

func up_rect() -> Rect2:
	return Rect2(165, control_top() + 42, 126, 126)

func down_rect() -> Rect2:
	return Rect2(165, control_top() + 178, 126, 126)

func attack_rect() -> Rect2:
	return Rect2(472, control_top() + 28, 210, 78)

func tnt_rect() -> Rect2:
	return Rect2(472, control_top() + 118, 210, 68)

func shop_rect() -> Rect2:
	return Rect2(472, control_top() + 198, 210, 60)

func quests_rect() -> Rect2:
	return Rect2(472, control_top() + 268, 210, 52)

func pause_rect() -> Rect2:
	return Rect2(620, 116, 72, 40)

func menu_new_rect() -> Rect2:
	return Rect2(135, 500, 450, 88)

func menu_continue_rect() -> Rect2:
	return Rect2(135, 606, 450, 88)

func shop_pick_rect() -> Rect2:
	return Rect2(70, 290, 580, 100)

func shop_bag_rect() -> Rect2:
	return Rect2(70, 410, 580, 100)

func shop_armor_rect() -> Rect2:
	return Rect2(70, 530, 580, 100)

func shop_tnt_rect() -> Rect2:
	return Rect2(70, 650, 580, 100)

func back_rect() -> Rect2:
	return Rect2(90, screen_h() - 120, 540, 78)

func quest_claim_rect() -> Rect2:
	return Rect2(90, 650, 540, 86)

func pause_resume_rect() -> Rect2:
	return Rect2(150, 500, 420, 80)

func pause_menu_rect() -> Rect2:
	return Rect2(150, 600, 420, 80)

func game_over_rect() -> Rect2:
	return Rect2(140, 650, 440, 86)

func max_hp() -> int:
	return 100 + (armor_level - 1) * 20

func armor_reduction() -> int:
	return (armor_level - 1) * 2

func bag_capacity() -> int:
	return 15 + (bag_level - 1) * 10

func bag_used() -> int:
	var total: int = 0
	for key in inventory.keys():
		total += int(inventory[key])
	return total

func pick_damage() -> int:
	return pick_level

func combat_damage() -> int:
	return 2 + pick_level * 2

func pick_price() -> int:
	return 90 * pick_level * pick_level

func bag_price() -> int:
	return 75 * bag_level * bag_level

func armor_price() -> int:
	return 120 * armor_level * armor_level

func cashout_multiplier() -> float:
	var tiers: int = int(run_max_depth / 20)
	return minf(2.50, 1.0 + float(tiers) * 0.15)

func critical_chance() -> float:
	return minf(0.30, 0.05 + float(pick_level) * 0.025)

func combat_hit_damage() -> Dictionary:
	var crit: bool = rng.randf() < critical_chance()
	var damage: int = combat_damage() * (2 if crit else 1)
	if frenzy_turns > 0:
		damage = int(round(float(damage) * 1.5))
	return {"damage":damage,"crit":crit}

func mining_hit_damage() -> Dictionary:
	var crit: bool = rng.randf() < critical_chance()
	var damage: int = pick_damage() * (2 if crit else 1)
	if frenzy_turns > 0:
		damage += 1
	return {"damage":damage,"crit":crit}

func roll_contract() -> void:
	var roll: int = rng.randi_range(0,2)
	contract_paid = false
	if roll == 0:
		contract_type = "ore"
		contract_target = rng.randi_range(18,30)
		contract_reward = 140 + contract_target * 4
	elif roll == 1:
		contract_type = "kills"
		contract_target = rng.randi_range(4,7)
		contract_reward = 180 + contract_target * 20
	else:
		contract_type = "depth"
		contract_target = rng.randi_range(2,4) * 20
		contract_reward = 160 + contract_target * 4

func contract_progress_value() -> int:
	if contract_type == "ore":
		return run_ore
	if contract_type == "kills":
		return run_kills
	return run_max_depth

func contract_complete() -> bool:
	return contract_progress_value() >= contract_target

func contract_text() -> String:
	var title: String = "Добыть руду"
	if contract_type == "kills":
		title = "Победить врагов"
	elif contract_type == "depth":
		title = "Достичь глубины"
	return title + ": " + str(mini(contract_progress_value(),contract_target)) + "/" + str(contract_target) + "  •  +" + str(contract_reward)

func settle_contract() -> void:
	if contract_paid or not contract_complete():
		return
	coins += contract_reward
	contract_paid = true
	say("КОНТРАКТ ВЫПОЛНЕН! +" + str(contract_reward) + " монет")

func add_frenzy(amount: int) -> void:
	if frenzy_turns > 0:
		return
	frenzy_charge = mini(100, frenzy_charge + amount)
	if frenzy_charge >= 100:
		frenzy_charge = 0
		frenzy_turns = 8
		say("ЗОЛОТАЯ ЛИХОРАДКА! Добыча x2 на 8 ходов")

func add_ore(t: String, base_amount: int = 1) -> int:
	var space: int = bag_capacity() - bag_used()
	if space <= 0:
		return 0
	var amount: int = base_amount
	if frenzy_turns > 0:
		amount *= 2
	if rng.randf() < 0.12:
		amount += 1
	amount = mini(amount, space)
	inventory[t] = int(inventory[t]) + amount
	lifetime_ore += amount
	run_ore += amount
	combo += 1
	combo_grace = 2
	add_frenzy(12 + amount * 2)
	if combo > 0 and combo % 5 == 0:
		var bonus: int = combo * 3
		coins += bonus
		say("СЕРИЯ x" + str(combo) + "! +" + str(bonus) + " монет")
	return amount

func open_geode() -> void:
	var choices: Array[String] = ["iron","gold","diamond","ruby"]
	var index: int = rng.randi_range(0,choices.size()-1)
	var ore: String = choices[index]
	var amount: int = rng.randi_range(1,3)
	var gained: int = add_ore(ore,amount)
	if rng.randf() < 0.30:
		potions += 1
		say("ГЕОДА: +" + str(gained) + " " + ore_name(ore) + " и аптечка")
	else:
		say("ГЕОДА: +" + str(gained) + " " + ore_name(ore))

func use_potion() -> void:
	if potions <= 0:
		say("Аптечек нет")
		return
	if hp >= max_hp():
		say("Здоровье уже полное")
		return
	potions -= 1
	hp = mini(max_hp(), hp + 40)
	say("Аптечка: +40 HP")
	finish_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		handle_touch(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_touch(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			handle_back()
			return
		if state != GameState.PLAY:
			return
		match event.keycode:
			KEY_A, KEY_LEFT:
				try_move(Vector2i.LEFT)
			KEY_D, KEY_RIGHT:
				try_move(Vector2i.RIGHT)
			KEY_W, KEY_UP:
				try_move(Vector2i.UP)
			KEY_S, KEY_DOWN:
				try_move(Vector2i.DOWN)
			KEY_SPACE:
				attack()
			KEY_T:
				use_tnt()

func handle_back() -> void:
	if state == GameState.PLAY:
		state = GameState.PAUSE
	elif state in [GameState.SHOP, GameState.QUESTS, GameState.PAUSE]:
		state = GameState.PLAY
	queue_redraw()

func handle_touch(pos: Vector2) -> void:
	if state == GameState.MENU:
		if menu_new_rect().has_point(pos):
			generate_mine()
			save_all()
			state = GameState.PLAY
		elif menu_continue_rect().has_point(pos):
			state = GameState.PLAY
		queue_redraw()
		return

	if state == GameState.PAUSE:
		if pause_resume_rect().has_point(pos):
			state = GameState.PLAY
		elif pause_menu_rect().has_point(pos):
			save_all()
			state = GameState.MENU
		queue_redraw()
		return

	if state == GameState.SHOP:
		if shop_pick_rect().has_point(pos):
			upgrade_pick()
		elif shop_bag_rect().has_point(pos):
			upgrade_bag()
		elif shop_armor_rect().has_point(pos):
			upgrade_armor()
		elif shop_tnt_rect().has_point(pos):
			buy_tnt()
		elif back_rect().has_point(pos):
			state = GameState.PLAY
		queue_redraw()
		return

	if state == GameState.QUESTS:
		if quest_claim_rect().has_point(pos):
			claim_quest()
		elif back_rect().has_point(pos):
			state = GameState.PLAY
		queue_redraw()
		return

	if state == GameState.GAME_OVER:
		if game_over_rect().has_point(pos):
			respawn()
		queue_redraw()
		return

	if state != GameState.PLAY:
		return

	if pause_rect().has_point(pos):
		save_all()
		state = GameState.PAUSE
	elif left_rect().has_point(pos):
		try_move(Vector2i.LEFT)
	elif right_rect().has_point(pos):
		try_move(Vector2i.RIGHT)
	elif up_rect().has_point(pos):
		try_move(Vector2i.UP)
	elif down_rect().has_point(pos):
		try_move(Vector2i.DOWN)
	elif attack_rect().has_point(pos):
		attack()
	elif tnt_rect().has_point(pos):
		if player.y <= SURFACE_ROW:
			buy_tnt()
		else:
			use_tnt()
	elif shop_rect().has_point(pos):
		if player.y <= SURFACE_ROW:
			state = GameState.SHOP
		else:
			say("Магазин только на поверхности")
	elif quests_rect().has_point(pos):
		if player.y <= SURFACE_ROW:
			state = GameState.QUESTS
		else:
			use_potion()
	queue_redraw()

func generate_mine() -> void:
	world.clear()
	hazards.clear()
	enemies.clear()
	boss.clear()
	boss_defeated = false
	inventory = {"coal":0,"iron":0,"gold":0,"diamond":0,"ruby":0}

	for y in range(ROWS):
		var row: Array = []
		for x in range(COLS):
			if y <= SURFACE_ROW:
				row.append(null)
			else:
				row.append(make_block(y))
		world.append(row)

	for y in range(2, 8):
		world[y][5] = null

	for y in range(8, ROWS):
		for x in range(COLS):
			if rng.randf() < 0.05:
				world[y][x] = null
				var p := Vector2i(x, y)
				if y > 30 and rng.randf() < hazard_chance(y):
					hazards[p] = hazard_kind(y)
				elif rng.randf() < 0.20:
					spawn_enemy(p, y)

	var boss_y: int = 92
	for yy in range(boss_y - 2, boss_y + 3):
		for xx in range(3, 9):
			world[yy][xx] = null
			hazards.erase(Vector2i(xx, yy))
	remove_enemies_in(Rect2i(3, boss_y - 2, 6, 5))
	boss = {"pos":Vector2i(6,boss_y),"hp":55,"max_hp":55,"damage":18}

	player = Vector2i(5, SURFACE_ROW)
	facing = Vector2i.DOWN
	hp = max_hp()
	turn_count = 0
	run_max_depth = 0
	run_ore = 0
	run_kills = 0
	combo = 0
	combo_grace = 0
	frenzy_charge = 0
	frenzy_turns = 0
	roll_contract()
	mine_loaded = true
	say("Новая шахта. Контракт: " + contract_text())

func make_block(depth: int) -> Dictionary:
	var t: String = "dirt"
	var r: float = rng.randf()

	if depth > 35 and r < 0.009:
		t = "geode"
	elif depth > 110 and r < 0.015:
		t = "chest_epic"
	elif depth > 50 and r < 0.024:
		t = "chest_rare"
	elif depth > 12 and r < 0.044:
		t = "chest"
	else:
		var ore: float = rng.randf()
		if depth < 25:
			if ore < 0.16:
				t = "coal"
			elif ore < 0.24:
				t = "stone"
		elif depth < 55:
			if ore < 0.12:
				t = "coal"
			elif ore < 0.24:
				t = "iron"
			elif ore < 0.34:
				t = "stone"
		elif depth < 100:
			if ore < 0.10:
				t = "iron"
			elif ore < 0.20:
				t = "gold"
			elif ore < 0.27:
				t = "diamond"
			elif ore < 0.38:
				t = "stone"
		else:
			if ore < 0.09:
				t = "gold"
			elif ore < 0.18:
				t = "diamond"
			elif ore < 0.24:
				t = "ruby"
			elif ore < 0.40:
				t = "stone"

	var block_hp: int = 1
	match t:
		"coal":
			block_hp = 1
		"iron":
			block_hp = 2
		"stone":
			block_hp = 2
		"gold":
			block_hp = 3
		"diamond":
			block_hp = 4
		"ruby":
			block_hp = 5
		"chest", "chest_rare", "chest_epic":
			block_hp = 2
		"geode":
			block_hp = 3

	return {"type":t,"hp":block_hp,"max_hp":block_hp}

func hazard_chance(depth: int) -> float:
	if depth < 55:
		return 0.05
	if depth < 100:
		return 0.08
	return 0.12

func hazard_kind(depth: int) -> String:
	if depth < 70:
		return "spikes"
	if depth < 125:
		return "lava"
	return "crystal"

func spawn_enemy(pos: Vector2i, depth: int) -> void:
	var kind: String = "slime"
	var enemy_hp: int = 5
	var damage: int = 7
	var reward: int = 12
	if depth >= 45 and rng.randf() < 0.55:
		kind = "bat"
		enemy_hp = 6
		damage = 9
		reward = 18
	if depth >= 80 and rng.randf() < 0.35:
		kind = "golem"
		enemy_hp = 10
		damage = 13
		reward = 32
	if depth >= 125 and rng.randf() < 0.25:
		kind = "crystal"
		enemy_hp = 13
		damage = 15
		reward = 45
	enemies.append({"pos":pos,"kind":kind,"hp":enemy_hp,"max_hp":enemy_hp,"damage":damage,"reward":reward})

func remove_enemies_in(area: Rect2i) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var p: Vector2i = enemies[i]["pos"]
		if area.has_point(p):
			enemies.remove_at(i)

func try_move(dir: Vector2i) -> void:
	facing = dir
	var target: Vector2i = player + dir
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return
	if enemy_at(target) >= 0:
		attack()
		return
	if boss.size() > 0 and not boss_defeated and boss["pos"] == target:
		attack()
		return
	if world[target.y][target.x] != null:
		attack()
		return

	player = target
	if player.y > max_depth:
		max_depth = player.y
	run_max_depth = maxi(run_max_depth, player.y - SURFACE_ROW)

	if hazards.has(player):
		resolve_hazard(player)
		if hp <= 0:
			return

	if player.y <= SURFACE_ROW:
		sell_all()
		settle_contract()
		hp = max_hp()
		if message_time <= 0.0:
			say("На поверхности: добыча продана, здоровье восстановлено")

	finish_turn()

func attack() -> void:
	if state != GameState.PLAY:
		return
	var target: Vector2i = player + facing
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return

	if boss.size() > 0 and not boss_defeated and boss["pos"] == target:
		var hit: Dictionary = combat_hit_damage()
		boss["hp"] = int(boss["hp"]) - int(hit["damage"])
		if int(boss["hp"]) <= 0:
			boss_defeated = true
			bosses_killed += 1
			run_kills += 1
			coins += 650
			tnt += 2
			add_frenzy(30)
			say("БОСС ПОВЕРЖЕН! +650 монет и +2 TNT")
		else:
			say(("КРИТ! " if bool(hit["crit"]) else "") + "Урон боссу: " + str(hit["damage"]))
		finish_turn()
		return

	var enemy_idx: int = enemy_at(target)
	if enemy_idx >= 0:
		var enemy: Dictionary = enemies[enemy_idx]
		var hit: Dictionary = combat_hit_damage()
		enemy["hp"] = int(enemy["hp"]) - int(hit["damage"])
		if int(enemy["hp"]) <= 0:
			var reward: int = int(enemy["reward"])
			coins += reward
			run_kills += 1
			add_frenzy(20)
			enemies.remove_at(enemy_idx)
			say(("КРИТ! " if bool(hit["crit"]) else "") + "Враг повержен: +" + str(reward))
		else:
			enemies[enemy_idx] = enemy
			say(("КРИТ! " if bool(hit["crit"]) else "") + "Урон: " + str(hit["damage"]))
		finish_turn()
		return

	var block = world[target.y][target.x]
	if block == null:
		say("Перед тобой пусто")
		return

	var t: String = str(block["type"])
	if is_ore(t) and bag_used() >= bag_capacity():
		say("Рюкзак заполнен")
		return

	var mine_hit: Dictionary = mining_hit_damage()
	block["hp"] = int(block["hp"]) - int(mine_hit["damage"])
	if int(block["hp"]) <= 0:
		world[target.y][target.x] = null
		resolve_broken_block(t)
		player = target
		run_max_depth = maxi(run_max_depth, player.y - SURFACE_ROW)
		max_depth = maxi(max_depth, player.y)
	else:
		world[target.y][target.x] = block
		say(("КРИТ! " if bool(mine_hit["crit"]) else "") + "Кирка: -" + str(mine_hit["damage"]))
	finish_turn()

func resolve_broken_block(t: String) -> void:
	if is_ore(t):
		var gained: int = add_ore(t,1)
		if message_time <= 0.0 or combo % 5 != 0:
			say("+" + str(gained) + " " + ore_name(t) + "  •  серия x" + str(combo))
	elif t == "geode":
		open_geode()
	elif t.begins_with("chest"):
		open_chest(t)
	elif t == "stone":
		say("Камень разбит")
	else:
		say("Проход расчищен")

func is_ore(t: String) -> bool:
	return t in ["coal","iron","gold","diamond","ruby"]

func open_chest(t: String) -> void:
	var reward: int = rng.randi_range(25, 70)
	var gain_tnt: int = 0
	if t == "chest_rare":
		reward = rng.randi_range(90, 170)
		gain_tnt = 1
	elif t == "chest_epic":
		reward = rng.randi_range(220, 420)
		gain_tnt = 2
	coins += reward
	tnt += gain_tnt
	var potion_gain: int = 1 if rng.randf() < (0.55 if t != "chest" else 0.20) else 0
	potions += potion_gain
	add_frenzy(15)
	say("Сундук: +" + str(reward) + " мон., +" + str(gain_tnt) + " TNT" + (" + аптечка" if potion_gain > 0 else ""))

func resolve_hazard(pos: Vector2i) -> void:
	var kind: String = str(hazards[pos])
	if kind == "lava":
		take_damage(18, "Лава")
	elif kind == "spikes":
		take_damage(10, "Шипы")
	else:
		if bag_used() < bag_capacity() and rng.randf() < 0.45:
			var gained: int = add_ore("diamond",1)
			say("Кристальная жила: +" + str(gained) + " алмаз")
		else:
			take_damage(8, "Кристалл")

func finish_turn() -> void:
	turn_count += 1
	if frenzy_turns > 0:
		frenzy_turns -= 1
	if combo_grace > 0:
		combo_grace -= 1
	elif combo > 0:
		combo = 0
	enemies_turn()
	boss_turn()
	check_quest_progress()
	save_all()
	queue_redraw()

func enemies_turn() -> void:
	if enemies.is_empty() or player.y <= SURFACE_ROW:
		return
	var occupied: Dictionary = {}
	for e in enemies:
		occupied[e["pos"]] = true

	for i in range(enemies.size()):
		if hp <= 0:
			return
		var e: Dictionary = enemies[i]
		var p: Vector2i = e["pos"]
		var dist: int = abs(p.x - player.x) + abs(p.y - player.y)

		if dist == 1:
			take_damage(int(e["damage"]), enemy_name(str(e["kind"])))
			if hp <= 0:
				return
			continue

		var kind: String = str(e["kind"])
		if kind == "crystal" and dist == 2 and turn_count % 2 == 0:
			take_damage(maxi(1,int(e["damage"]) - 4),"Кристальный выстрел")
			if hp <= 0:
				return
			continue

		var cadence: int = 2
		if kind == "bat":
			cadence = 1
		elif kind == "golem":
			cadence = 3
		if dist > (8 if kind == "bat" else 6) or turn_count % cadence != 0:
			continue

		var dirs: Array = []
		var dx: int = signi(player.x - p.x)
		var dy: int = signi(player.y - p.y)
		if abs(player.x - p.x) >= abs(player.y - p.y):
			if dx != 0:
				dirs.append(Vector2i(dx,0))
			if dy != 0:
				dirs.append(Vector2i(0,dy))
		else:
			if dy != 0:
				dirs.append(Vector2i(0,dy))
			if dx != 0:
				dirs.append(Vector2i(dx,0))

		for d in dirs:
			var np: Vector2i = p + d
			if enemy_can_move(np, occupied):
				occupied.erase(p)
				e["pos"] = np
				occupied[np] = true
				enemies[i] = e
				break

func boss_turn() -> void:
	if boss.size() == 0 or boss_defeated or hp <= 0:
		return
	var p: Vector2i = boss["pos"]
	var dist: int = abs(p.x - player.x) + abs(p.y - player.y)
	if dist == 1:
		take_damage(int(boss["damage"]), "Каменный Голем")
		return
	if dist > 5 or turn_count % 2 != 0:
		return

	var dx: int = signi(player.x - p.x)
	var dy: int = signi(player.y - p.y)
	var np: Vector2i = p
	if abs(player.x - p.x) >= abs(player.y - p.y) and dx != 0:
		np += Vector2i(dx,0)
	elif dy != 0:
		np += Vector2i(0,dy)
	if boss_can_move(np):
		boss["pos"] = np

func enemy_can_move(pos: Vector2i, occupied: Dictionary) -> bool:
	if pos.x < 0 or pos.x >= COLS or pos.y <= SURFACE_ROW or pos.y >= ROWS:
		return false
	if pos == player or occupied.has(pos) or hazards.has(pos):
		return false
	if boss.size() > 0 and not boss_defeated and boss["pos"] == pos:
		return false
	return world[pos.y][pos.x] == null

func boss_can_move(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= COLS or pos.y <= SURFACE_ROW or pos.y >= ROWS:
		return false
	if pos == player or hazards.has(pos):
		return false
	if enemy_at(pos) >= 0:
		return false
	return world[pos.y][pos.x] == null

func enemy_at(pos: Vector2i) -> int:
	for i in range(enemies.size()):
		if enemies[i]["pos"] == pos:
			return i
	return -1

func enemy_name(kind: String) -> String:
	if kind == "bat":
		return "Летучая мышь"
	if kind == "golem":
		return "Каменный зверёк"
	if kind == "crystal":
		return "Кристальный жук"
	return "Слизень"

func take_damage(amount: int, source: String) -> void:
	var damage: int = maxi(1, amount - armor_reduction())
	hp = maxi(0, hp - damage)
	say(source + ": -" + str(damage) + " HP")
	if hp <= 0:
		var lost: int = int(coins * 0.05)
		coins = maxi(0, coins - lost)
		for key in inventory.keys():
			inventory[key] = 0
		message = "Шахтёр потерял сознание. Потеряно " + str(lost) + " монет"
		message_time = 99.0
		state = GameState.GAME_OVER
		save_all()

func respawn() -> void:
	player = Vector2i(5, SURFACE_ROW)
	facing = Vector2i.DOWN
	hp = max_hp()
	state = GameState.PLAY
	say("Ты снова на поверхности")
	save_all()

func use_tnt() -> void:
	if player.y <= SURFACE_ROW:
		buy_tnt()
		return
	if tnt <= 0:
		say("TNT закончился")
		return
	tnt -= 1

	for oy in range(-1,2):
		for ox in range(-1,2):
			var p: Vector2i = player + Vector2i(ox,oy)
			if p.x < 0 or p.x >= COLS or p.y <= SURFACE_ROW or p.y >= ROWS or p == player:
				continue

			if boss.size() > 0 and not boss_defeated and boss["pos"] == p:
				boss["hp"] = int(boss["hp"]) - 15
				if int(boss["hp"]) <= 0:
					boss_defeated = true
					bosses_killed += 1
					coins += 600

			var ei: int = enemy_at(p)
			if ei >= 0:
				coins += int(enemies[ei]["reward"])
				run_kills += 1
				add_frenzy(20)
				enemies.remove_at(ei)

			var block = world[p.y][p.x]
			if block != null:
				var t: String = str(block["type"])
				if is_ore(t) and bag_used() < bag_capacity():
					add_ore(t,1)
				elif t.begins_with("chest"):
					open_chest(t)
				world[p.y][p.x] = null

	say("БУМ! Область расчищена")
	finish_turn()

func sell_all() -> void:
	var earned: int = 0
	earned += int(inventory["coal"]) * 4
	earned += int(inventory["iron"]) * 10
	earned += int(inventory["gold"]) * 28
	earned += int(inventory["diamond"]) * 85
	earned += int(inventory["ruby"]) * 180
	if earned <= 0:
		return
	var multiplier: float = cashout_multiplier()
	var payout: int = int(round(float(earned) * multiplier))
	coins += payout
	for key in inventory.keys():
		inventory[key] = 0
	say("Продано: +" + str(payout) + "  •  множитель x" + str(snappedf(multiplier,0.05)))

func upgrade_pick() -> void:
	var price: int = pick_price()
	if coins < price:
		say("Нужно " + str(price) + " монет")
		return
	coins -= price
	pick_level += 1
	say("Кирка улучшена до ур. " + str(pick_level))
	save_all()

func upgrade_bag() -> void:
	var price: int = bag_price()
	if coins < price:
		say("Нужно " + str(price) + " монет")
		return
	coins -= price
	bag_level += 1
	say("Рюкзак: " + str(bag_capacity()) + " мест")
	save_all()

func upgrade_armor() -> void:
	var price: int = armor_price()
	if coins < price:
		say("Нужно " + str(price) + " монет")
		return
	coins -= price
	armor_level += 1
	hp = max_hp()
	say("Броня улучшена до ур. " + str(armor_level))
	save_all()

func buy_tnt() -> void:
	if coins < 35:
		say("На TNT нужно 35 монет")
		return
	coins -= 35
	tnt += 1
	say("Куплен 1 TNT")
	save_all()

func quest_data() -> Array:
	return [
		{"title":"Первая смена","desc":"Добудь 20 единиц руды","type":"ore","target":20,"reward":120},
		{"title":"Глубже","desc":"Достигни глубины 50 м","type":"depth","target":50,"reward":220},
		{"title":"Богатая жила","desc":"Добудь всего 100 единиц руды","type":"ore","target":100,"reward":400},
		{"title":"Страж глубин","desc":"Победи Каменного Голема","type":"boss","target":1,"reward":800}
	]

func quest_progress() -> int:
	if quest_index >= quest_data().size():
		return 0
	var q: Dictionary = quest_data()[quest_index]
	var qtype: String = str(q["type"])
	if qtype == "ore":
		return lifetime_ore
	if qtype == "depth":
		return maxi(0, max_depth - SURFACE_ROW)
	if qtype == "boss":
		return bosses_killed
	return 0

func quest_complete() -> bool:
	if quest_index >= quest_data().size():
		return false
	var q: Dictionary = quest_data()[quest_index]
	return quest_progress() >= int(q["target"])

func claim_quest() -> void:
	if quest_index >= quest_data().size():
		say("Все задания выполнены")
		return
	if not quest_complete():
		say("Задание ещё не выполнено")
		return
	var q: Dictionary = quest_data()[quest_index]
	var reward: int = int(q["reward"])
	coins += reward
	quest_index += 1
	say("Награда: +" + str(reward) + " монет")
	save_all()

func check_quest_progress() -> void:
	if quest_complete():
		say("Задание выполнено! Забери награду на поверхности")

func ore_name(t: String) -> String:
	if t == "coal":
		return "уголь"
	if t == "iron":
		return "железо"
	if t == "gold":
		return "золото"
	if t == "diamond":
		return "алмаз"
	if t == "ruby":
		return "рубин"
	return t

func say(text: String) -> void:
	message = text
	message_time = 2.7

func save_all() -> void:
	save_meta()
	save_mine()

func save_meta() -> void:
	var data: Dictionary = {
		"coins":coins,
		"pick_level":pick_level,
		"bag_level":bag_level,
		"armor_level":armor_level,
		"tnt":tnt,
		"max_depth":max_depth,
		"lifetime_ore":lifetime_ore,
		"bosses_killed":bosses_killed,
		"quest_index":quest_index,
		"potions":potions
	}
	var f := FileAccess.open(META_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_meta() -> void:
	if not FileAccess.file_exists(META_SAVE):
		return
	var f := FileAccess.open(META_SAVE, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	coins = int(data.get("coins",0))
	pick_level = maxi(1,int(data.get("pick_level",1)))
	bag_level = maxi(1,int(data.get("bag_level",1)))
	armor_level = maxi(1,int(data.get("armor_level",1)))
	tnt = maxi(0,int(data.get("tnt",2)))
	max_depth = maxi(0,int(data.get("max_depth",0)))
	lifetime_ore = maxi(0,int(data.get("lifetime_ore",0)))
	bosses_killed = maxi(0,int(data.get("bosses_killed",0)))
	quest_index = clampi(int(data.get("quest_index",0)),0,4)
	potions = maxi(0,int(data.get("potions",1)))

func save_mine() -> void:
	if world.size() != ROWS:
		return
	var hazard_data: Array = []
	for p in hazards.keys():
		hazard_data.append({"x":p.x,"y":p.y,"kind":str(hazards[p])})

	var enemy_data: Array = []
	for e in enemies:
		var ep: Vector2i = e["pos"]
		enemy_data.append({
			"x":ep.x,"y":ep.y,"kind":str(e["kind"]),
			"hp":int(e["hp"]),"max_hp":int(e["max_hp"]),
			"damage":int(e["damage"]),"reward":int(e["reward"])
		})

	var boss_data: Dictionary = {}
	if boss.size() > 0:
		var bp: Vector2i = boss["pos"]
		boss_data = {
			"x":bp.x,"y":bp.y,
			"hp":int(boss["hp"]),"max_hp":int(boss["max_hp"]),
			"damage":int(boss["damage"])
		}

	var data: Dictionary = {
		"world":world,
		"hazards":hazard_data,
		"enemies":enemy_data,
		"boss":boss_data,
		"boss_defeated":boss_defeated,
		"player":{"x":player.x,"y":player.y},
		"facing":{"x":facing.x,"y":facing.y},
		"hp":hp,
		"inventory":inventory,
		"turn_count":turn_count,
		"run_max_depth":run_max_depth,
		"run_ore":run_ore,
		"run_kills":run_kills,
		"combo":combo,
		"combo_grace":combo_grace,
		"frenzy_charge":frenzy_charge,
		"frenzy_turns":frenzy_turns,
		"contract_type":contract_type,
		"contract_target":contract_target,
		"contract_reward":contract_reward,
		"contract_paid":contract_paid
	}
	var f := FileAccess.open(MINE_SAVE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_mine() -> bool:
	if not FileAccess.file_exists(MINE_SAVE):
		return false
	var f := FileAccess.open(MINE_SAVE, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("world") or typeof(data["world"]) != TYPE_ARRAY:
		return false
	if data["world"].size() != ROWS:
		return false

	world = data["world"]
	hazards.clear()
	for h in data.get("hazards",[]):
		hazards[Vector2i(int(h["x"]),int(h["y"]))] = str(h["kind"])

	enemies.clear()
	for e in data.get("enemies",[]):
		enemies.append({
			"pos":Vector2i(int(e["x"]),int(e["y"])),
			"kind":str(e["kind"]),
			"hp":int(e["hp"]),"max_hp":int(e["max_hp"]),
			"damage":int(e["damage"]),"reward":int(e["reward"])
		})

	boss.clear()
	var bd = data.get("boss",{})
	if typeof(bd) == TYPE_DICTIONARY and bd.size() > 0:
		boss = {
			"pos":Vector2i(int(bd["x"]),int(bd["y"])),
			"hp":int(bd["hp"]),"max_hp":int(bd["max_hp"]),
			"damage":int(bd["damage"])
		}
	boss_defeated = bool(data.get("boss_defeated",false))

	var pd = data.get("player",{"x":5,"y":SURFACE_ROW})
	player = Vector2i(int(pd.get("x",5)),int(pd.get("y",SURFACE_ROW)))
	var fd = data.get("facing",{"x":0,"y":1})
	facing = Vector2i(int(fd.get("x",0)),int(fd.get("y",1)))
	hp = clampi(int(data.get("hp",max_hp())),1,max_hp())
	turn_count = maxi(0,int(data.get("turn_count",0)))
	run_max_depth = maxi(0,int(data.get("run_max_depth",maxi(0,player.y-SURFACE_ROW))))
	run_ore = maxi(0,int(data.get("run_ore",0)))
	run_kills = maxi(0,int(data.get("run_kills",0)))
	combo = maxi(0,int(data.get("combo",0)))
	combo_grace = maxi(0,int(data.get("combo_grace",0)))
	frenzy_charge = clampi(int(data.get("frenzy_charge",0)),0,100)
	frenzy_turns = maxi(0,int(data.get("frenzy_turns",0)))
	contract_type = str(data.get("contract_type","ore"))
	contract_target = maxi(1,int(data.get("contract_target",20)))
	contract_reward = maxi(1,int(data.get("contract_reward",150)))
	contract_paid = bool(data.get("contract_paid",false))

	var inv = data.get("inventory",{})
	for key in inventory.keys():
		inventory[key] = int(inv.get(key,0))
	return true

func camera_offset_y() -> float:
	return mine_center_y() - float(player.y) * TILE

func tile_pos(x: int, y: int) -> Vector2:
	return Vector2(GRID_X + x*TILE, camera_offset_y() + y*TILE)

func biome_name(depth: int) -> String:
	if depth < 25:
		return "Земляные штольни"
	if depth < 55:
		return "Каменные пещеры"
	if depth < 100:
		return "Золотой пласт"
	if depth < 130:
		return "Магмовые глубины"
	return "Кристальные недра"

func block_color(t: String) -> Color:
	match t:
		"dirt":
			return Color("#6e472b")
		"stone":
			return Color("#656b72")
		"coal":
			return Color("#26292d")
		"iron":
			return Color("#a66b48")
		"gold":
			return Color("#d6a72c")
		"diamond":
			return Color("#2bc9dc")
		"ruby":
			return Color("#cf3c58")
		"chest":
			return Color("#9c632f")
		"chest_rare":
			return Color("#466bb1")
		"chest_epic":
			return Color("#8951b3")
		"geode":
			return Color("#5f4a83")
		_:
			return Color("#6e472b")

func _draw() -> void:
	match state:
		GameState.MENU:
			draw_menu()
		GameState.PLAY:
			draw_game()
		GameState.SHOP:
			draw_shop()
		GameState.QUESTS:
			draw_quests()
		GameState.PAUSE:
			draw_game()
			draw_pause()
		GameState.GAME_OVER:
			draw_game()
			draw_game_over()

func draw_menu() -> void:
	var h: float = screen_h()
	draw_rect(Rect2(0,0,BASE_W,h),Color("#10151c"))
	draw_rect(Rect2(0,h-370,BASE_W,370),Color("#573820"))
	draw_string(ThemeDB.fallback_font,Vector2(0,205),"ШАХТЁР",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,58,Color("#f3c43e"))
	draw_string(ThemeDB.fallback_font,Vector2(0,268),"ГЛУБЖЕ!",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,52,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(0,320),"arcade-версия 0.7",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,19,Color("#b9c3cc"))
	draw_menu_button(menu_new_rect(),"НОВАЯ ШАХТА")
	draw_menu_button(menu_continue_rect(),"ПРОДОЛЖИТЬ")
	draw_string(ThemeDB.fallback_font,Vector2(0,750),"Рекорд: "+str(maxi(0,max_depth-SURFACE_ROW))+" м",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,23,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(0,790),"Монеты: "+str(coins)+"  •  Боссов: "+str(bosses_killed),HORIZONTAL_ALIGNMENT_CENTER,BASE_W,19,Color("#d3dae0"))
	draw_miner(Vector2(360,h-205),2.1)

func draw_game() -> void:
	var h: float = screen_h()
	draw_rect(Rect2(0,0,BASE_W,h),Color("#0f141a"))

	var min_y: int = maxi(0,player.y-10)
	var max_y: int = mini(ROWS-1,player.y+10)
	for y in range(min_y,max_y+1):
		for x in range(COLS):
			var p: Vector2 = tile_pos(x,y)
			var r := Rect2(p,Vector2(TILE-1,TILE-1))
			if y <= SURFACE_ROW:
				draw_rect(r,Color("#83c9ff"))
			else:
				var cell := Vector2i(x,y)
				var block = world[y][x]
				if block == null:
					draw_rect(r,Color("#171c22"))
					if hazards.has(cell):
						draw_hazard(r,str(hazards[cell]))
				else:
					var t: String = str(block["type"])
					var c: Color = block_color(t)
					draw_rect(r,c)
					draw_rect(r.grow(-3),c.lightened(0.10),false,2)
					if is_ore(t):
						draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),8,c.lightened(0.38))
					if t.begins_with("chest"):
						draw_chest(r,t)
					elif t == "geode":
						draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),13,Color("#b78cff"))
						draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),6,Color("#e8dcff"))
					if int(block["hp"]) < int(block["max_hp"]):
						var ratio: float = float(block["hp"]) / float(block["max_hp"])
						draw_rect(Rect2(r.position+Vector2(5,TILE-7),Vector2((TILE-10)*ratio,4)),Color.WHITE)

	for e in enemies:
		var ep: Vector2i = e["pos"]
		if ep.y >= min_y and ep.y <= max_y:
			draw_enemy(e)

	if boss.size() > 0 and not boss_defeated:
		var bp: Vector2i = boss["pos"]
		if bp.y >= min_y and bp.y <= max_y:
			draw_boss()

	var pp: Vector2 = tile_pos(player.x,player.y)+Vector2(TILE*0.5,TILE*0.5)
	draw_miner(pp,0.62)
	draw_facing_marker(pp)

	draw_hud()
	draw_controls()

func draw_hud() -> void:
	draw_rect(Rect2(0,0,BASE_W,TOP_H),Color(0.04,0.05,0.07,0.97))
	draw_string(ThemeDB.fallback_font,Vector2(18,31),"ШАХТЁР: ГЛУБЖЕ!  v0.7",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#f5d36b"))
	draw_string(ThemeDB.fallback_font,Vector2(18,69),"Монеты: "+str(coins),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(210,69),"Рюкзак: "+str(bag_used())+"/"+str(bag_capacity()),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(470,69),"Глубина: "+str(maxi(0,player.y-SURFACE_ROW))+" м",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(18,105),"Кирка "+str(pick_level)+"  •  Броня "+str(armor_level)+"  •  TNT "+str(tnt)+"  •  Аптечки "+str(potions),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c7d0d8"))
	draw_string(ThemeDB.fallback_font,Vector2(18,139),biome_name(maxi(0,player.y-SURFACE_ROW))+"  •  риск x"+str(snappedf(cashout_multiplier(),0.05))+"  •  серия x"+str(combo),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e4b657"))
	draw_rect(Rect2(445,112,158,18),Color("#3a2225"))
	draw_rect(Rect2(445,112,158*(float(hp)/float(max_hp())),18),Color("#50b86d"))
	draw_string(ThemeDB.fallback_font,Vector2(493,132),str(hp)+"/"+str(max_hp()),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
	draw_rect(Rect2(445,140,158,8),Color("#292333"))
	var frenzy_ratio: float = 1.0 if frenzy_turns > 0 else float(frenzy_charge)/100.0
	draw_rect(Rect2(445,140,158*frenzy_ratio,8),Color("#f2b84b") if frenzy_turns == 0 else Color("#ffd95b"))
	draw_small_button(pause_rect(),"II",true)

	draw_rect(Rect2(45,TOP_H+8,630,50),Color(0,0,0,0.76))
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(60,TOP_H+40),message,HORIZONTAL_ALIGNMENT_CENTER,600,17,Color.WHITE)
	else:
		var contract_line: String = ("✓ " if contract_complete() else "Контракт: ") + contract_text()
		draw_string(ThemeDB.fallback_font,Vector2(60,TOP_H+40),contract_line,HORIZONTAL_ALIGNMENT_CENTER,600,15,Color("#f2d476"))

func draw_controls() -> void:
	var top: float = control_top()
	draw_rect(Rect2(0,top,BASE_W,BOTTOM_H),Color(0.04,0.05,0.07,0.97))
	draw_move_button(left_rect(),"←")
	draw_move_button(right_rect(),"→")
	draw_move_button(up_rect(),"↑")
	draw_move_button(down_rect(),"↓")
	draw_action_button(attack_rect(),"УДАР / КИРКА",true,Color("#8a542d"))
	draw_action_button(tnt_rect(),("КУПИТЬ TNT • 35" if player.y <= SURFACE_ROW else "TNT • "+str(tnt)),true,Color("#783d38"))
	draw_action_button(shop_rect(),"МАГАЗИН",player.y <= SURFACE_ROW,Color("#315f43"))
	draw_action_button(quests_rect(),("ЗАДАНИЯ" if player.y <= SURFACE_ROW else "АПТЕЧКА • "+str(potions)),true,Color("#315f43"))

func draw_hazard(r: Rect2, kind: String) -> void:
	if kind == "lava":
		draw_rect(r,Color("#ad2d1e"))
		draw_rect(Rect2(r.position+Vector2(0,9),Vector2(r.size.x,8)),Color("#f27225"))
		draw_circle(r.position+Vector2(17,32),5,Color("#ffd05a"))
	elif kind == "spikes":
		draw_polygon(PackedVector2Array([
			r.position+Vector2(3,r.size.y),r.position+Vector2(14,16),
			r.position+Vector2(26,r.size.y),r.position+Vector2(39,15),
			r.position+Vector2(50,r.size.y)
		]),PackedColorArray([Color("#a9b2ba")]))
	else:
		draw_polygon(PackedVector2Array([
			r.position+Vector2(8,46),r.position+Vector2(18,11),
			r.position+Vector2(29,46),r.position+Vector2(38,19),
			r.position+Vector2(48,46)
		]),PackedColorArray([Color("#747bea")]))

func draw_chest(r: Rect2, t: String) -> void:
	var band: Color = Color("#e7bd46")
	if t == "chest_rare":
		band = Color("#b6d3ff")
	elif t == "chest_epic":
		band = Color("#edc0ff")
	draw_rect(Rect2(r.position+Vector2(7,18),Vector2(r.size.x-14,25)),block_color(t))
	draw_rect(Rect2(r.position+Vector2(7,11),Vector2(r.size.x-14,12)),band.darkened(0.45))
	draw_rect(Rect2(r.position+Vector2(23,20),Vector2(7,12)),band)

func draw_enemy(e: Dictionary) -> void:
	var pos: Vector2i = e["pos"]
	var c: Vector2 = tile_pos(pos.x,pos.y)+Vector2(TILE*0.5,TILE*0.5)
	var kind: String = str(e["kind"])
	if kind == "bat":
		draw_circle(c,10,Color("#8d5aac"))
		draw_line(c+Vector2(-7,0),c+Vector2(-23,-10),Color("#70458e"),8)
		draw_line(c+Vector2(7,0),c+Vector2(23,-10),Color("#70458e"),8)
	elif kind == "golem":
		draw_rect(Rect2(c+Vector2(-18,-16),Vector2(36,32)),Color("#8a8177"))
		draw_rect(Rect2(c+Vector2(-12,-8),Vector2(7,6)),Color("#ef5d4a"))
		draw_rect(Rect2(c+Vector2(5,-8),Vector2(7,6)),Color("#ef5d4a"))
	elif kind == "crystal":
		draw_circle(c,16,Color("#5964cc"))
		draw_line(c,c+Vector2(-16,-17),Color("#a0a6ff"),5)
		draw_line(c,c+Vector2(16,-17),Color("#a0a6ff"),5)
	else:
		draw_circle(c+Vector2(0,5),18,Color("#4aaf6e"))
		draw_circle(c+Vector2(-6,1),3,Color.WHITE)
		draw_circle(c+Vector2(6,1),3,Color.WHITE)

	var ratio: float = float(e["hp"]) / float(e["max_hp"])
	draw_rect(Rect2(c+Vector2(-19,-27),Vector2(38,4)),Color("#52282d"))
	draw_rect(Rect2(c+Vector2(-19,-27),Vector2(38*ratio,4)),Color("#df6262"))

func draw_boss() -> void:
	var p: Vector2i = boss["pos"]
	var c: Vector2 = tile_pos(p.x,p.y)+Vector2(TILE*0.5,TILE*0.5)
	draw_rect(Rect2(c+Vector2(-24,-23),Vector2(48,46)),Color("#716960"))
	draw_rect(Rect2(c+Vector2(-17,-13),Vector2(9,7)),Color("#ff5a45"))
	draw_rect(Rect2(c+Vector2(8,-13),Vector2(9,7)),Color("#ff5a45"))
	draw_line(c+Vector2(-29,2),c+Vector2(-21,2),Color("#91877c"),10)
	draw_line(c+Vector2(29,2),c+Vector2(21,2),Color("#91877c"),10)
	var ratio: float = float(boss["hp"]) / float(boss["max_hp"])
	draw_rect(Rect2(c+Vector2(-30,-34),Vector2(60,6)),Color("#421f23"))
	draw_rect(Rect2(c+Vector2(-30,-34),Vector2(60*ratio,6)),Color("#e05b4e"))

func draw_miner(p: Vector2, scale: float) -> void:
	draw_circle(p+Vector2(0,-9*scale),18*scale,Color("#dfad6a"))
	draw_rect(Rect2(p+Vector2(-20*scale,-30*scale),Vector2(40*scale,9*scale)),Color("#e2ad29"))
	draw_rect(Rect2(p+Vector2(-13*scale,-38*scale),Vector2(26*scale,10*scale)),Color("#f0c33e"))
	draw_circle(p+Vector2(0,-32*scale),4*scale,Color("#fff1a0"))
	draw_rect(Rect2(p+Vector2(-14*scale,8*scale),Vector2(28*scale,27*scale)),Color("#386b94"))
	draw_rect(Rect2(p+Vector2(-12*scale,-14*scale),Vector2(4*scale,4*scale)),Color("#252a30"))
	draw_rect(Rect2(p+Vector2(8*scale,-14*scale),Vector2(4*scale,4*scale)),Color("#252a30"))

func draw_facing_marker(p: Vector2) -> void:
	var v := Vector2(facing.x,facing.y)*23.0
	draw_circle(p+v,4,Color("#f8dc72"))

func draw_shop() -> void:
	draw_screen_bg("МАГАЗИН")
	draw_string(ThemeDB.fallback_font,Vector2(0,155),"Монеты: "+str(coins),HORIZONTAL_ALIGNMENT_CENTER,BASE_W,24,Color.WHITE)
	draw_shop_card(shop_pick_rect(),"Кирка ур. "+str(pick_level),"Урон по породе: "+str(pick_damage()),pick_price())
	draw_shop_card(shop_bag_rect(),"Рюкзак "+str(bag_capacity())+" мест","Больше добычи за один спуск",bag_price())
	draw_shop_card(shop_armor_rect(),"Броня ур. "+str(armor_level),"HP "+str(max_hp())+" • защита "+str(armor_reduction()),armor_price())
	draw_shop_card(shop_tnt_rect(),"Динамит x"+str(tnt),"Взрыв области 3×3",35)
	draw_menu_button(back_rect(),"НАЗАД")
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(55,815),message,HORIZONTAL_ALIGNMENT_CENTER,610,18,Color.WHITE)

func draw_quests() -> void:
	draw_screen_bg("ЗАДАНИЯ")
	if quest_index >= quest_data().size():
		draw_string(ThemeDB.fallback_font,Vector2(0,360),"Все задания выполнены!",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,30,Color.WHITE)
	else:
		var q: Dictionary = quest_data()[quest_index]
		draw_string(ThemeDB.fallback_font,Vector2(0,300),str(q["title"]),HORIZONTAL_ALIGNMENT_CENTER,BASE_W,32,Color.WHITE)
		draw_string(ThemeDB.fallback_font,Vector2(60,360),str(q["desc"]),HORIZONTAL_ALIGNMENT_CENTER,600,21,Color("#c9d1d8"))
		draw_string(ThemeDB.fallback_font,Vector2(0,430),str(quest_progress())+" / "+str(q["target"]),HORIZONTAL_ALIGNMENT_CENTER,BASE_W,31,Color("#f3c54b"))
		draw_string(ThemeDB.fallback_font,Vector2(0,485),"Награда: "+str(q["reward"])+" монет",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,22,Color.WHITE)
		draw_menu_button(quest_claim_rect(),"ЗАБРАТЬ НАГРАДУ" if quest_complete() else "ЕЩЁ НЕ ВЫПОЛНЕНО")
	draw_menu_button(back_rect(),"НАЗАД")
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(55,790),message,HORIZONTAL_ALIGNMENT_CENTER,610,18,Color.WHITE)

func draw_pause() -> void:
	draw_rect(Rect2(0,0,BASE_W,screen_h()),Color(0,0,0,0.74))
	draw_string(ThemeDB.fallback_font,Vector2(0,405),"ПАУЗА",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,42,Color.WHITE)
	draw_menu_button(pause_resume_rect(),"ПРОДОЛЖИТЬ")
	draw_menu_button(pause_menu_rect(),"В ГЛАВНОЕ МЕНЮ")

func draw_game_over() -> void:
	draw_rect(Rect2(0,0,BASE_W,screen_h()),Color(0.06,0.02,0.02,0.84))
	draw_string(ThemeDB.fallback_font,Vector2(0,465),"СМЕНА ОКОНЧЕНА",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,40,Color("#ff8c7a"))
	draw_string(ThemeDB.fallback_font,Vector2(50,535),message,HORIZONTAL_ALIGNMENT_CENTER,620,19,Color.WHITE)
	draw_menu_button(game_over_rect(),"ВЕРНУТЬСЯ НА ПОВЕРХНОСТЬ")

func draw_screen_bg(title: String) -> void:
	draw_rect(Rect2(0,0,BASE_W,screen_h()),Color("#111820"))
	draw_string(ThemeDB.fallback_font,Vector2(0,92),title,HORIZONTAL_ALIGNMENT_CENTER,BASE_W,43,Color("#f2c74d"))

func draw_shop_card(r: Rect2, title: String, desc: String, price: int) -> void:
	draw_rect(r,Color("#253240"))
	draw_rect(r.grow(-3),Color("#405164"),false,2)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(18,34),title,HORIZONTAL_ALIGNMENT_LEFT,350,21,Color.WHITE)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(18,66),desc,HORIZONTAL_ALIGNMENT_LEFT,360,15,Color("#c4ccd3"))
	draw_string(ThemeDB.fallback_font,r.position+Vector2(420,58),str(price)+" мон.",HORIZONTAL_ALIGNMENT_CENTER,135,17,Color("#f2c74d"))

func draw_menu_button(r: Rect2, label: String) -> void:
	draw_rect(r,Color("#2d465c"))
	draw_rect(r.grow(-4),Color("#52708b"),false,3)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y*0.5+8),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,20,Color.WHITE)

func draw_move_button(r: Rect2, label: String) -> void:
	draw_rect(r,Color("#284735"))
	draw_rect(r.grow(-4),Color("#4c7b5f"),false,3)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y*0.5+17),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,42,Color.WHITE)

func draw_small_button(r: Rect2, label: String, enabled: bool) -> void:
	var c: Color = Color("#315f43") if enabled else Color("#33383d")
	draw_rect(r,c)
	draw_rect(r.grow(-3),c.lightened(0.16),false,2)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y*0.5+6),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,14,Color.WHITE)

func draw_action_button(r: Rect2, label: String, enabled: bool, base_color: Color) -> void:
	var c: Color = base_color if enabled else Color("#33383d")
	draw_rect(r,c)
	draw_rect(r.grow(-3),c.lightened(0.16),false,2)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y*0.5+6),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,15,Color.WHITE)
