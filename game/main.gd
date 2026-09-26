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
const FLASHLIGHT_RADIUS: int = 5
const TORCH_RADIUS: int = 3
const FLASHLIGHT_DRAIN: float = 1.0
const JOYSTICK_RADIUS: float = 108.0
const JOYSTICK_DEADZONE: float = 28.0
const JOYSTICK_INITIAL_REPEAT: float = 0.30
const JOYSTICK_REPEAT: float = 0.18

enum GameState { MENU, PLAY, SHOP, QUESTS, FACTORY, LOGISTICS, PAUSE, GAME_OVER }

const RAIL_COST: int = 15
const UNLOAD_STATION_COST: int = 350

const FACTORIES: Array = [
	{
		"name":"УГОЛЬНАЯ ТЭЦ",
		"short":"ТЭЦ",
		"x":1,
		"accepted":["coal"],
		"prices":{"coal":8},
		"base_seconds":12.0,
		"seconds_per_unit":2.0
	},
	{
		"name":"МЕТАЛЛУРГИЧЕСКИЙ ЗАВОД",
		"short":"МЕТАЛЛ",
		"x":6,
		"accepted":["iron"],
		"prices":{"iron":22},
		"base_seconds":18.0,
		"seconds_per_unit":3.0
	},
	{
		"name":"ОБОГАТИТЕЛЬНЫЙ КОМБИНАТ",
		"short":"КОМБИНАТ",
		"x":10,
		"accepted":["gold","diamond","ruby"],
		"prices":{"gold":65,"diamond":190,"ruby":340},
		"base_seconds":25.0,
		"seconds_per_unit":4.0
	}
]

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

# v0.8 lighting and atmosphere
var flashlight_on: bool = true
var battery_capacity: int = 100
var battery_level: float = 100.0
var torch_count: int = 2
var torches: Dictionary = {}

# v0.9 factories and processing economy
var selected_factory: int = -1
var factory_storage: Array = [
	{"coal":0},
	{"iron":0},
	{"gold":0,"diamond":0,"ruby":0}
]
var factory_finish_time: Array = [0.0,0.0,0.0]
var factory_pending_payout: Array = [0,0,0]
var factory_ready_balance: Array = [0,0,0]
var factory_tick_accum: float = 0.0

# v1.0 mine logistics
var rail_tiles: Dictionary = {}
var unload_stations: Dictionary = {}

var inventory: Dictionary = {
	"coal": 0,
	"iron": 0,
	"gold": 0,
	"diamond": 0,
	"ruby": 0
}

var message: String = ""
var message_time: float = 0.0

# Virtual joystick
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_offset: Vector2 = Vector2.ZERO
var joystick_dir: Vector2i = Vector2i.ZERO
var joystick_repeat_timer: float = 0.0

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

	factory_tick_accum += delta
	if factory_tick_accum >= 0.5:
		factory_tick_accum = 0.0
		process_factory_automation()

	if state == GameState.PLAY and joystick_active and joystick_dir != Vector2i.ZERO:
		joystick_repeat_timer -= delta
		if joystick_repeat_timer <= 0.0:
			try_move(joystick_dir)
			joystick_repeat_timer = JOYSTICK_REPEAT
	queue_redraw()

func screen_h() -> float:
	return get_viewport_rect().size.y

func control_top() -> float:
	return screen_h() - BOTTOM_H

func mine_center_y() -> float:
	return (TOP_H + control_top()) * 0.5

func joystick_center() -> Vector2:
	return Vector2(230.0, control_top() + 220.0)

func joystick_hit(pos: Vector2) -> bool:
	return pos.distance_to(joystick_center()) <= JOYSTICK_RADIUS + 34.0

func joystick_direction(offset: Vector2) -> Vector2i:
	if offset.length() < JOYSTICK_DEADZONE:
		return Vector2i.ZERO
	if abs(offset.x) > abs(offset.y):
		return Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP

func update_joystick(pos: Vector2, immediate_on_change: bool) -> void:
	var raw: Vector2 = pos - joystick_center()
	if raw.length() > JOYSTICK_RADIUS:
		raw = raw.normalized() * JOYSTICK_RADIUS
	joystick_offset = raw
	var new_dir: Vector2i = joystick_direction(raw)
	if new_dir != joystick_dir:
		joystick_dir = new_dir
		joystick_repeat_timer = JOYSTICK_INITIAL_REPEAT
		if immediate_on_change and joystick_dir != Vector2i.ZERO:
			try_move(joystick_dir)

func release_joystick() -> void:
	joystick_active = false
	joystick_touch_index = -1
	joystick_offset = Vector2.ZERO
	joystick_dir = Vector2i.ZERO
	joystick_repeat_timer = 0.0

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

func light_rect() -> Rect2:
	return Rect2(472, control_top() + 326, 210, 48)

func logistics_rect() -> Rect2:
	return Rect2(472, control_top() + 380, 210, 46)

func logistics_station_rect() -> Rect2:
	return Rect2(85, 350, 550, 90)

func logistics_rail_rect() -> Rect2:
	return Rect2(85, 465, 550, 90)

func logistics_unload_rect() -> Rect2:
	return Rect2(85, 580, 550, 90)

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

func shop_torch_rect() -> Rect2:
	return Rect2(70, 770, 580, 96)

func shop_battery_rect() -> Rect2:
	return Rect2(70, 886, 580, 96)

func factory_ore_rect(slot: int) -> Rect2:
	return Rect2(70, 260 + slot * 125, 580, 105)

func factory_start_rect() -> Rect2:
	return Rect2(90, 690, 540, 82)

func factory_claim_rect() -> Rect2:
	return Rect2(90, 790, 540, 82)

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

func torch_price() -> int:
	return 25

func battery_upgrade_price() -> int:
	var step: int = maxi(0, int((battery_capacity - 100) / 25.0))
	return 160 + step * 140

func light_strength(pos: Vector2i) -> float:
	if pos.y <= SURFACE_ROW:
		return 1.0
	var best: float = 0.0
	var dx: float = float(pos.x - player.x)
	var dy: float = float(pos.y - player.y)
	var dist: float = sqrt(dx*dx + dy*dy)

	# Minimal visibility around the miner even with a dead lamp.
	best = maxf(best, clampf(0.22 * (1.0 - dist / 1.6), 0.0, 0.22))

	if flashlight_on and battery_level > 0.0:
		var lamp: float = clampf(1.0 - dist / float(FLASHLIGHT_RADIUS + 1), 0.0, 1.0)
		best = maxf(best, lamp)

	for key in torches.keys():
		var tp: Vector2i = key
		var tx: float = float(pos.x - tp.x)
		var ty: float = float(pos.y - tp.y)
		var td: float = sqrt(tx*tx + ty*ty)
		var torch_light: float = clampf(1.0 - td / float(TORCH_RADIUS + 1), 0.0, 1.0)
		best = maxf(best, torch_light)

	return best

func is_lit(pos: Vector2i) -> bool:
	return light_strength(pos) > 0.08

func drain_flashlight() -> void:
	if player.y <= SURFACE_ROW:
		battery_level = float(battery_capacity)
		flashlight_on = true
		return
	if flashlight_on and battery_level > 0.0:
		battery_level = maxf(0.0, battery_level - FLASHLIGHT_DRAIN)
		if battery_level <= 0.0:
			flashlight_on = false
			say("ФОНАРЬ ПОГАС: аккумулятор разряжен")

func toggle_flashlight() -> void:
	if player.y <= SURFACE_ROW:
		say("На поверхности фонарь заряжается")
		return
	if not flashlight_on and battery_level <= 0.0:
		say("Аккумулятор пуст — вернись на поверхность")
		return
	flashlight_on = not flashlight_on
	say("Фонарь " + ("включён" if flashlight_on else "выключен"))

func place_torch() -> void:
	if player.y <= SURFACE_ROW:
		say("Факелы нужны под землёй")
		return
	if torch_count <= 0:
		say("Факелы закончились")
		return
	if torches.has(player):
		say("Здесь уже установлен факел")
		return
	torches[player] = true
	torch_count -= 1
	say("Факел установлен")
	finish_turn()

func buy_torch() -> void:
	var price: int = torch_price()
	if coins < price:
		say("Нужно " + str(price) + " монет")
		return
	coins -= price
	torch_count += 1
	say("Куплен факел")
	save_all()

func upgrade_battery() -> void:
	if battery_capacity >= 250:
		say("Аккумулятор уже максимальный")
		return
	var price: int = battery_upgrade_price()
	if coins < price:
		say("Нужно " + str(price) + " монет")
		return
	coins -= price
	battery_capacity += 25
	battery_level = float(battery_capacity)
	say("Аккумулятор улучшен до " + str(battery_capacity))
	save_all()

func nearby_factory_index() -> int:
	if player.y > SURFACE_ROW:
		return -1
	var best: int = -1
	var best_dist: int = 999
	for i in range(FACTORIES.size()):
		var fx: int = int(FACTORIES[i]["x"])
		var d: int = abs(player.x - fx)
		if d <= 1 and d < best_dist:
			best = i
			best_dist = d
	return best

func factory_processing(index: int) -> bool:
	if index < 0 or index >= FACTORIES.size():
		return false
	return float(factory_finish_time[index]) > Time.get_unix_time_from_system()

func factory_ready(index: int) -> bool:
	if index < 0 or index >= FACTORIES.size():
		return false
	return int(factory_ready_balance[index]) > 0

func factory_seconds_left(index: int) -> int:
	if not factory_processing(index):
		return 0
	return maxi(0,int(ceil(float(factory_finish_time[index]) - Time.get_unix_time_from_system())))

func start_factory_batch(index: int, announce: bool = false) -> bool:
	if index < 0 or index >= FACTORIES.size():
		return false
	if factory_processing(index):
		return false
	var units: int = factory_stored_units(index)
	if units <= 0:
		return false

	var payout: int = factory_stored_value(index)
	var data: Dictionary = FACTORIES[index]
	var seconds: float = float(data["base_seconds"]) + float(units) * float(data["seconds_per_unit"])
	seconds = minf(seconds,180.0)

	factory_pending_payout[index] = payout
	factory_finish_time[index] = Time.get_unix_time_from_system() + seconds

	var storage: Dictionary = factory_storage[index]
	for ore in storage.keys():
		storage[ore] = 0
	factory_storage[index] = storage

	if announce:
		say("Переработка запущена • " + str(int(ceil(seconds))) + " сек.")
	return true

func process_factory_automation() -> void:
	var changed: bool = false
	var now: float = Time.get_unix_time_from_system()

	for i in range(FACTORIES.size()):
		var finish: float = float(factory_finish_time[i])
		if finish > 0.0 and finish <= now and int(factory_pending_payout[i]) > 0:
			factory_ready_balance[i] = int(factory_ready_balance[i]) + int(factory_pending_payout[i])
			factory_pending_payout[i] = 0
			factory_finish_time[i] = 0.0
			changed = true

		if not factory_processing(i) and factory_stored_units(i) > 0:
			if start_factory_batch(i,false):
				changed = true

	if changed:
		save_meta()

func factory_stored_units(index: int) -> int:
	var total: int = 0
	var storage: Dictionary = factory_storage[index]
	for ore in storage.keys():
		total += int(storage[ore])
	return total

func factory_stored_value(index: int) -> int:
	var total: int = 0
	var storage: Dictionary = factory_storage[index]
	var prices: Dictionary = FACTORIES[index]["prices"]
	for ore in storage.keys():
		total += int(storage[ore]) * int(prices.get(ore,0))
	return total

func factory_transfer_all(index: int, ore: String) -> void:
	if index < 0 or index >= FACTORIES.size():
		return
	var accepted: Array = FACTORIES[index]["accepted"]
	if not accepted.has(ore):
		say("Этот завод не принимает " + ore_name(ore))
		return
	var amount: int = int(inventory.get(ore,0))
	if amount <= 0:
		say("В рюкзаке нет: " + ore_name(ore))
		return
	var storage: Dictionary = factory_storage[index]
	storage[ore] = int(storage.get(ore,0)) + amount
	factory_storage[index] = storage
	inventory[ore] = 0
	say("Передано на завод: " + str(amount) + " × " + ore_name(ore))
	save_all()

func factory_start(index: int) -> void:
	if index < 0 or index >= FACTORIES.size():
		return
	if factory_processing(index):
		say("Завод уже перерабатывает партию")
		return
	if factory_stored_units(index) <= 0:
		say("Склад завода пуст")
		return
	if start_factory_batch(index,true):
		save_all()

func factory_claim(index: int) -> void:
	if index < 0 or index >= FACTORIES.size():
		return
	process_factory_automation()
	var payout: int = int(factory_ready_balance[index])
	if payout <= 0:
		say("Готовой выплаты пока нет")
		return
	coins += payout
	factory_ready_balance[index] = 0
	say("Забрано с завода +" + str(payout) + " монет")
	save_all()

func open_nearby_factory() -> void:
	var idx: int = nearby_factory_index()
	if idx < 0:
		say("Подойди ближе к заводу")
		return
	release_joystick()
	selected_factory = idx
	state = GameState.FACTORY

func logistics_open() -> void:
	release_joystick()
	state = GameState.LOGISTICS

func rail_can_build_here(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= COLS or pos.y < 0 or pos.y >= ROWS:
		return false
	if pos.y > SURFACE_ROW and world[pos.y][pos.x] != null:
		return false
	if hazards.has(pos):
		return false
	return true

func build_rail_here() -> void:
	if not rail_can_build_here(player):
		say("Рельсы кладутся только по расчищенному пути")
		return
	if rail_tiles.has(player):
		say("Здесь уже лежат рельсы")
		return
	if coins < RAIL_COST:
		say("Нужно " + str(RAIL_COST) + " монет на секцию рельс")
		return
	coins -= RAIL_COST
	rail_tiles[player] = true
	say("Рельсы проложены • -" + str(RAIL_COST) + " монет")
	save_all()

func build_unload_station_here() -> void:
	if player.y <= SURFACE_ROW:
		say("Пункт выгрузки строится только под землёй")
		return
	if not rail_can_build_here(player):
		say("Нужно расчищенное безопасное место")
		return
	if unload_stations.has(player):
		say("Здесь уже есть пункт выгрузки")
		return
	if coins < UNLOAD_STATION_COST:
		say("Нужно " + str(UNLOAD_STATION_COST) + " монет")
		return
	coins -= UNLOAD_STATION_COST
	unload_stations[player] = true
	rail_tiles[player] = true
	say("Пункт выгрузки построен")
	save_all()

func rail_connected_to_surface(station: Vector2i) -> bool:
	if not unload_stations.has(station):
		return false
	var queue: Array[Vector2i] = [station]
	var visited: Dictionary = {station:true}
	var dirs: Array[Vector2i] = [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]

	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		if p.y <= SURFACE_ROW and rail_tiles.has(p):
			return true
		for d in dirs:
			var np: Vector2i = p + d
			if visited.has(np):
				continue
			if rail_tiles.has(np):
				visited[np] = true
				queue.append(np)
	return false

func ore_factory_index(ore: String) -> int:
	for i in range(FACTORIES.size()):
		var accepted: Array = FACTORIES[i]["accepted"]
		if accepted.has(ore):
			return i
	return -1

func unload_bag_to_rail() -> void:
	if not unload_stations.has(player):
		say("Встань на пункт выгрузки")
		return
	if not rail_connected_to_surface(player):
		say("Нет непрерывных рельс до поверхности")
		return
	if bag_used() <= 0:
		say("Рюкзак пуст")
		return

	var moved: int = 0
	for ore in inventory.keys():
		var amount: int = int(inventory[ore])
		if amount <= 0:
			continue
		var idx: int = ore_factory_index(str(ore))
		if idx < 0:
			continue
		var storage: Dictionary = factory_storage[idx]
		storage[ore] = int(storage.get(ore,0)) + amount
		factory_storage[idx] = storage
		inventory[ore] = 0
		moved += amount

	if moved <= 0:
		say("Нет руды для отправки")
		return

	process_factory_automation()
	say("Отправлено по рельсам: " + str(moved) + " ед. • заводы запущены")
	save_all()

func rail_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		if rail_tiles.has(pos + d):
			out.append(d)
	return out

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
	if event is InputEventScreenTouch:
		if event.pressed:
			if state == GameState.PLAY and joystick_hit(event.position) and not joystick_active:
				joystick_active = true
				joystick_touch_index = event.index
				update_joystick(event.position,true)
			else:
				handle_touch(event.position)
		elif event.index == joystick_touch_index:
			release_joystick()
	elif event is InputEventScreenDrag:
		if joystick_active and event.index == joystick_touch_index:
			update_joystick(event.position,true)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if state == GameState.PLAY and joystick_hit(event.position):
				joystick_active = true
				joystick_touch_index = -2
				update_joystick(event.position,true)
			else:
				handle_touch(event.position)
		elif joystick_touch_index == -2:
			release_joystick()
	elif event is InputEventMouseMotion and joystick_touch_index == -2:
		update_joystick(event.position,true)
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
			KEY_F:
				toggle_flashlight()
			KEY_R:
				place_torch()

func handle_back() -> void:
	release_joystick()
	if state == GameState.PLAY:
		state = GameState.PAUSE
	elif state in [GameState.SHOP, GameState.QUESTS, GameState.FACTORY, GameState.LOGISTICS, GameState.PAUSE]:
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
		elif shop_torch_rect().has_point(pos):
			buy_torch()
		elif shop_battery_rect().has_point(pos):
			upgrade_battery()
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

	if state == GameState.FACTORY:
		if selected_factory >= 0 and selected_factory < FACTORIES.size():
			var accepted: Array = FACTORIES[selected_factory]["accepted"]
			for slot in range(accepted.size()):
				if factory_ore_rect(slot).has_point(pos):
					factory_transfer_all(selected_factory,str(accepted[slot]))
					queue_redraw()
					return
			if factory_start_rect().has_point(pos):
				factory_start(selected_factory)
			elif factory_claim_rect().has_point(pos):
				factory_claim(selected_factory)
			elif back_rect().has_point(pos):
				selected_factory = -1
				state = GameState.PLAY
		queue_redraw()
		return

	if state == GameState.LOGISTICS:
		if logistics_station_rect().has_point(pos):
			build_unload_station_here()
		elif logistics_rail_rect().has_point(pos):
			build_rail_here()
		elif logistics_unload_rect().has_point(pos):
			unload_bag_to_rail()
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
		release_joystick()
		save_all()
		state = GameState.PAUSE
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
			place_torch()
	elif quests_rect().has_point(pos):
		if player.y <= SURFACE_ROW:
			state = GameState.QUESTS
		else:
			use_potion()
	elif light_rect().has_point(pos):
		if player.y <= SURFACE_ROW:
			open_nearby_factory()
		else:
			toggle_flashlight()
	elif logistics_rect().has_point(pos):
		logistics_open()
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
	torches.clear()
	rail_tiles.clear()
	unload_stations.clear()
	battery_level = float(battery_capacity)
	flashlight_on = true
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
		say("Впереди враг — жми УДАР / КИРКА")
		return
	if boss.size() > 0 and not boss_defeated and boss["pos"] == target:
		say("Впереди босс — жми УДАР / КИРКА")
		return
	if world[target.y][target.x] != null:
		say("Впереди порода — жми УДАР / КИРКА")
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
		settle_contract()
		hp = max_hp()
		battery_level = float(battery_capacity)
		flashlight_on = true
		if message_time <= 0.0:
			say("Поверхность: отвези добычу на нужный завод")

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
	drain_flashlight()
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
		"potions":potions,
		"battery_capacity":battery_capacity,
		"torch_count":torch_count,
		"factory_storage":factory_storage,
		"factory_finish_time":factory_finish_time,
		"factory_pending_payout":factory_pending_payout,
		"factory_ready_balance":factory_ready_balance
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
	battery_capacity = clampi(int(data.get("battery_capacity",100)),100,250)
	torch_count = maxi(0,int(data.get("torch_count",2)))
	battery_level = float(battery_capacity)

	var loaded_storage = data.get("factory_storage",factory_storage)
	if typeof(loaded_storage) == TYPE_ARRAY and loaded_storage.size() == FACTORIES.size():
		factory_storage = loaded_storage
	var loaded_finish = data.get("factory_finish_time",factory_finish_time)
	if typeof(loaded_finish) == TYPE_ARRAY and loaded_finish.size() == FACTORIES.size():
		factory_finish_time = loaded_finish
	var loaded_payout = data.get("factory_pending_payout",factory_pending_payout)
	if typeof(loaded_payout) == TYPE_ARRAY and loaded_payout.size() == FACTORIES.size():
		factory_pending_payout = loaded_payout
	var loaded_ready = data.get("factory_ready_balance",factory_ready_balance)
	if typeof(loaded_ready) == TYPE_ARRAY and loaded_ready.size() == FACTORIES.size():
		factory_ready_balance = loaded_ready
	process_factory_automation()

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

	var torch_data: Array = []
	for tp in torches.keys():
		torch_data.append({"x":tp.x,"y":tp.y})

	var rail_data: Array = []
	for rp in rail_tiles.keys():
		rail_data.append({"x":rp.x,"y":rp.y})
	var station_data: Array = []
	for sp in unload_stations.keys():
		station_data.append({"x":sp.x,"y":sp.y})

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
		"contract_paid":contract_paid,
		"battery_level":battery_level,
		"flashlight_on":flashlight_on,
		"torches":torch_data,
		"rails":rail_data,
		"unload_stations":station_data
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

	torches.clear()
	for td in data.get("torches",[]):
		torches[Vector2i(int(td["x"]),int(td["y"]))] = true

	rail_tiles.clear()
	for rd in data.get("rails",[]):
		rail_tiles[Vector2i(int(rd["x"]),int(rd["y"]))] = true
	unload_stations.clear()
	for sd in data.get("unload_stations",[]):
		unload_stations[Vector2i(int(sd["x"]),int(sd["y"]))] = true

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
	battery_level = clampf(float(data.get("battery_level",battery_capacity)),0.0,float(battery_capacity))
	flashlight_on = bool(data.get("flashlight_on",true))
	if battery_level <= 0.0:
		flashlight_on = false

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
		GameState.FACTORY:
			draw_factory()
		GameState.LOGISTICS:
			draw_logistics()
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
	draw_string(ThemeDB.fallback_font,Vector2(0,320),"логистическая версия 1.0",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,19,Color("#b9c3cc"))
	draw_menu_button(menu_new_rect(),"НОВАЯ ШАХТА")
	draw_menu_button(menu_continue_rect(),"ПРОДОЛЖИТЬ")
	draw_string(ThemeDB.fallback_font,Vector2(0,750),"Рекорд: "+str(maxi(0,max_depth-SURFACE_ROW))+" м",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,23,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(0,790),"Монеты: "+str(coins)+"  •  Боссов: "+str(bosses_killed),HORIZONTAL_ALIGNMENT_CENTER,BASE_W,19,Color("#d3dae0"))
	draw_miner(Vector2(360,h-205),2.1)

func draw_game() -> void:
	var h: float = screen_h()
	draw_rect(Rect2(0,0,BASE_W,h),Color("#0b0e11"))

	var min_y: int = maxi(0,player.y-10)
	var max_y: int = mini(ROWS-1,player.y+10)
	for y in range(min_y,max_y+1):
		for x in range(COLS):
			var p: Vector2 = tile_pos(x,y)
			var r := Rect2(p,Vector2(TILE-1,TILE-1))
			if y <= SURFACE_ROW:
				draw_rect(r,Color("#7899a6"))
			else:
				var cell := Vector2i(x,y)
				var block = world[y][x]
				if block == null:
					draw_rect(r,Color("#101417"))
					if hazards.has(cell) and is_lit(cell):
						draw_hazard(r,str(hazards[cell]))
				else:
					draw_mine_block(r,block,x,y)

	# Surface facilities are visual world objects and must be drawn during _draw().
	if player.y <= 8:
		draw_surface_factories()

	for rp in rail_tiles.keys():
		var rail_pos: Vector2i = rp
		if rail_pos.y >= min_y and rail_pos.y <= max_y:
			draw_rail(rail_pos)

	for sp in unload_stations.keys():
		var station_pos: Vector2i = sp
		if station_pos.y >= min_y and station_pos.y <= max_y:
			draw_unload_station(station_pos)

	for tp in torches.keys():
		var torch_pos: Vector2i = tp
		if torch_pos.y >= min_y and torch_pos.y <= max_y and is_lit(torch_pos):
			draw_torch(torch_pos)

	for e in enemies:
		var ep: Vector2i = e["pos"]
		if ep.y >= min_y and ep.y <= max_y and is_lit(ep):
			draw_enemy(e)

	if boss.size() > 0 and not boss_defeated:
		var bp: Vector2i = boss["pos"]
		if bp.y >= min_y and bp.y <= max_y and is_lit(bp):
			draw_boss()

	var pp: Vector2 = tile_pos(player.x,player.y)+Vector2(TILE*0.5,TILE*0.5)
	draw_miner(pp,0.62)
	draw_facing_marker(pp)

	# Darkness is cell-based so light from torches remains permanent in explored routes.
	for y in range(min_y,max_y+1):
		for x in range(COLS):
			if y <= SURFACE_ROW:
				continue
			var cell := Vector2i(x,y)
			var strength: float = light_strength(cell)
			if strength >= 0.98:
				continue
			var alpha: float = clampf(0.94 * (1.0 - strength),0.0,0.94)
			draw_rect(Rect2(tile_pos(x,y),Vector2(TILE,TILE)),Color(0,0,0,alpha))

	draw_hud()
	draw_controls()

func draw_mine_block(r: Rect2, block: Dictionary, x: int, y: int) -> void:
	var t: String = str(block["type"])
	var depth: int = maxi(0,y-SURFACE_ROW)
	var rock: Color = Color("#655044")
	if depth >= 25:
		rock = Color("#5b514c")
	if depth >= 55:
		rock = Color("#4d4d4b")
	if depth >= 100:
		rock = Color("#403d39")
	if depth >= 130:
		rock = Color("#35363b")
	if t == "stone":
		rock = rock.lightened(0.12)

	draw_rect(r,rock.darkened(0.28))
	draw_rect(r.grow(-2),rock)
	draw_line(r.position+Vector2(3,3),r.position+Vector2(r.size.x-3,3),rock.lightened(0.12),2.0)
	draw_line(r.position+Vector2(3,3),r.position+Vector2(3,r.size.y-3),rock.lightened(0.09),2.0)

	var seed: int = (x + 17) * 9187 + (y + 31) * 6791
	for i in range(3):
		var px: float = float((seed + i*19) % 30) + 10.0
		var py: float = float((int(seed / 7) + i*23) % 30) + 10.0
		draw_circle(r.position+Vector2(px,py),1.8,rock.lightened(0.08))

	if is_ore(t):
		draw_ore_veins(r,t)
	elif t.begins_with("chest"):
		draw_chest(r,t)
	elif t == "geode":
		draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),15,Color("#342f40"))
		draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),11,Color("#725892"))
		draw_circle(r.position+Vector2(TILE*0.5,TILE*0.5),5,Color("#bfa6db"))

	var current_hp: int = int(block["hp"])
	var block_max_hp: int = maxi(1,int(block["max_hp"]))
	if current_hp < block_max_hp:
		var crack: Color = Color(0.05,0.04,0.03,0.75)
		draw_line(r.position+Vector2(11,9),r.position+Vector2(27,25),crack,2.0)
		if current_hp * 2 <= block_max_hp:
			draw_line(r.position+Vector2(27,25),r.position+Vector2(19,43),crack,2.0)
			draw_line(r.position+Vector2(27,25),r.position+Vector2(41,17),crack,2.0)

func draw_ore_veins(r: Rect2, t: String) -> void:
	var ore_c: Color = Color("#25272a")
	if t == "iron":
		ore_c = Color("#9b7760")
	elif t == "gold":
		ore_c = Color("#d6ae45")
	elif t == "diamond":
		ore_c = Color("#76c8d8")
	elif t == "ruby":
		ore_c = Color("#b94a58")
	for pt in [Vector2(14,17),Vector2(31,14),Vector2(37,34),Vector2(20,37)]:
		draw_circle(r.position+pt,4.2,ore_c)
		draw_circle(r.position+pt-Vector2(1,1),1.2,ore_c.lightened(0.35))
	draw_line(r.position+Vector2(12,31),r.position+Vector2(41,20),ore_c.darkened(0.05),2.0)

func draw_torch(pos: Vector2i) -> void:
	var c: Vector2 = tile_pos(pos.x,pos.y)+Vector2(TILE*0.5,TILE*0.5)
	draw_circle(c,20,Color(1.0,0.72,0.25,0.10))
	draw_rect(Rect2(c+Vector2(-2,5),Vector2(4,16)),Color("#76502f"))
	draw_circle(c+Vector2(0,2),5,Color("#e8a740"))
	draw_circle(c+Vector2(0,0),2.5,Color("#fff0a2"))

func draw_hud() -> void:
	draw_rect(Rect2(0,0,BASE_W,TOP_H),Color(0.04,0.05,0.07,0.97))
	draw_string(ThemeDB.fallback_font,Vector2(18,31),"ШАХТЁР: ГЛУБЖЕ!  v1.0",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#f5d36b"))
	draw_string(ThemeDB.fallback_font,Vector2(18,69),"Монеты: "+str(coins),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(210,69),"Рюкзак: "+str(bag_used())+"/"+str(bag_capacity()),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(470,69),"Глубина: "+str(maxi(0,player.y-SURFACE_ROW))+" м",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(18,105),"Кирка "+str(pick_level)+"  •  Броня "+str(armor_level)+"  •  TNT "+str(tnt)+"  •  Факелы "+str(torch_count),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c7d0d8"))
	draw_string(ThemeDB.fallback_font,Vector2(18,139),biome_name(maxi(0,player.y-SURFACE_ROW))+"  •  риск x"+str(snappedf(cashout_multiplier(),0.05))+"  •  серия x"+str(combo),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e4b657"))
	draw_rect(Rect2(445,112,158,18),Color("#3a2225"))
	draw_rect(Rect2(445,112,158*(float(hp)/float(max_hp())),18),Color("#50b86d"))
	draw_string(ThemeDB.fallback_font,Vector2(493,132),str(hp)+"/"+str(max_hp()),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
	draw_rect(Rect2(445,138,158,8),Color("#27251e"))
	draw_rect(Rect2(445,138,158*(battery_level/float(battery_capacity)),8),Color("#e7c65b") if flashlight_on else Color("#77736a"))
	draw_rect(Rect2(445,151,158,6),Color("#292333"))
	var frenzy_ratio: float = 1.0 if frenzy_turns > 0 else float(frenzy_charge)/100.0
	draw_rect(Rect2(445,151,158*frenzy_ratio,6),Color("#f2b84b") if frenzy_turns == 0 else Color("#ffd95b"))
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
	draw_joystick()
	draw_action_button(attack_rect(),"УДАР / КИРКА",true,Color("#8a542d"))
	draw_action_button(tnt_rect(),("КУПИТЬ TNT • 35" if player.y <= SURFACE_ROW else "TNT • "+str(tnt)),true,Color("#783d38"))
	draw_action_button(shop_rect(),("МАГАЗИН" if player.y <= SURFACE_ROW else "ПОСТАВИТЬ ФАКЕЛ • "+str(torch_count)),true,Color("#554431"))
	draw_action_button(quests_rect(),("ЗАДАНИЯ" if player.y <= SURFACE_ROW else "АПТЕЧКА • "+str(potions)),true,Color("#315f43"))
	var near_factory: int = nearby_factory_index()
	var factory_label: String = "ЗАВОД • ПОДОЙДИ"
	if near_factory >= 0:
		factory_label = "ОТКРЫТЬ • " + str(FACTORIES[near_factory]["short"])
	draw_action_button(light_rect(),factory_label if player.y <= SURFACE_ROW else ("ФОНАРЬ: ВЫКЛ" if flashlight_on else "ФОНАРЬ: ВКЛ"),near_factory >= 0 if player.y <= SURFACE_ROW else true,Color("#5b5635"))
	draw_action_button(logistics_rect(),"РЕЛЬСЫ / ВЫГРУЗКА",true,Color("#4a4e52"))

func draw_joystick() -> void:
	var c: Vector2 = joystick_center()
	draw_circle(c,JOYSTICK_RADIUS,Color(0.08,0.10,0.09,0.96))
	draw_arc(c,JOYSTICK_RADIUS-3.0,0.0,TAU,48,Color("#59685f"),4.0)
	draw_arc(c,JOYSTICK_DEADZONE,0.0,TAU,32,Color(0.45,0.50,0.47,0.32),2.0)
	draw_line(c+Vector2(-JOYSTICK_RADIUS+18,0),c+Vector2(JOYSTICK_RADIUS-18,0),Color(0.35,0.40,0.37,0.18),2.0)
	draw_line(c+Vector2(0,-JOYSTICK_RADIUS+18),c+Vector2(0,JOYSTICK_RADIUS-18),Color(0.35,0.40,0.37,0.18),2.0)
	var knob: Vector2 = c + joystick_offset
	draw_circle(knob,42.0,Color("#46594e"))
	draw_circle(knob,35.0,Color("#64776b"))
	draw_circle(knob-Vector2(8,8),8.0,Color(1,1,1,0.10))
	draw_string(ThemeDB.fallback_font,Vector2(c.x-80,c.y+145),"ДВИЖЕНИЕ",HORIZONTAL_ALIGNMENT_CENTER,160,14,Color("#aeb8b1"))

func draw_surface_factories() -> void:
	for i in range(FACTORIES.size()):
		var data: Dictionary = FACTORIES[i]
		var x: int = int(data["x"])
		var ground: Vector2 = tile_pos(x,SURFACE_ROW)
		var c: Vector2 = ground + Vector2(TILE*0.5,TILE*0.5)

		var body: Color = Color("#4b5154")
		var roof: Color = Color("#353a3d")
		var accent: Color = Color("#b2753e")
		if i == 0:
			body = Color("#514a41")
			roof = Color("#37332f")
			accent = Color("#c39345")
		elif i == 1:
			body = Color("#555d62")
			roof = Color("#343b40")
			accent = Color("#aeb7bd")
		else:
			body = Color("#46515b")
			roof = Color("#313a43")
			accent = Color("#72a7c7")

		# Building body.
		draw_rect(Rect2(c+Vector2(-47,-102),Vector2(94,87)),body.darkened(0.18))
		draw_rect(Rect2(c+Vector2(-42,-96),Vector2(84,77)),body)
		draw_rect(Rect2(c+Vector2(-48,-104),Vector2(96,12)),roof)

		# Door and industrial windows.
		draw_rect(Rect2(c+Vector2(-10,-53),Vector2(20,34)),Color("#202529"))
		draw_rect(Rect2(c+Vector2(-33,-76),Vector2(16,20)),accent.darkened(0.12))
		draw_rect(Rect2(c+Vector2(18,-76),Vector2(16,20)),accent.darkened(0.12))
		draw_line(c+Vector2(-25,-76),c+Vector2(-25,-56),accent.lightened(0.25),2.0)
		draw_line(c+Vector2(26,-76),c+Vector2(26,-56),accent.lightened(0.25),2.0)

		# Chimney / processing stack.
		draw_rect(Rect2(c+Vector2(23,-140),Vector2(18,38)),Color("#5e6262"))
		draw_rect(Rect2(c+Vector2(20,-145),Vector2(24,7)),Color("#3d4142"))
		if factory_processing(i):
			draw_circle(c+Vector2(33,-154),10,Color(0.55,0.58,0.60,0.32))
			draw_circle(c+Vector2(40,-166),13,Color(0.55,0.58,0.60,0.20))

		# Status lamp.
		var status: Color = Color("#858b8f")
		if factory_ready(i):
			status = Color("#63d77b")
		elif factory_processing(i):
			status = Color("#e4ad4c")
		draw_circle(c+Vector2(-34,-113),7,status)

		# Label plate.
		draw_rect(Rect2(c+Vector2(-51,-132),Vector2(102,23)),Color(0.06,0.07,0.08,0.88))
		draw_string(ThemeDB.fallback_font,c+Vector2(-48,-115),str(data["short"]),HORIZONTAL_ALIGNMENT_CENTER,96,12,Color("#e8eaeb"))

func draw_factory() -> void:
	if selected_factory < 0 or selected_factory >= FACTORIES.size():
		state = GameState.PLAY
		return
	var data: Dictionary = FACTORIES[selected_factory]
	draw_screen_bg(str(data["name"]))
	draw_string(ThemeDB.fallback_font,Vector2(0,142),"РЮКЗАК → СКЛАД → ПЕРЕРАБОТКА → ДЕНЬГИ",HORIZONTAL_ALIGNMENT_CENTER,BASE_W,16,Color("#c9d0d5"))

	var accepted: Array = data["accepted"]
	var prices: Dictionary = data["prices"]
	for slot in range(accepted.size()):
		var ore: String = str(accepted[slot])
		var r: Rect2 = factory_ore_rect(slot)
		var storage: Dictionary = factory_storage[selected_factory]
		draw_rect(r,Color("#232c31"))
		draw_rect(r.grow(-3),Color("#465057"),false,2)
		draw_string(ThemeDB.fallback_font,r.position+Vector2(18,31),ore_name(ore).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,180,20,Color.WHITE)
		draw_string(ThemeDB.fallback_font,r.position+Vector2(18,61),"В рюкзаке: "+str(int(inventory.get(ore,0)))+"  •  На складе: "+str(int(storage.get(ore,0))),HORIZONTAL_ALIGNMENT_LEFT,360,15,Color("#c7ced3"))
		draw_string(ThemeDB.fallback_font,r.position+Vector2(18,87),str(int(prices.get(ore,0)))+" мон. после переработки",HORIZONTAL_ALIGNMENT_LEFT,300,14,Color("#e2bd61"))
		draw_rect(Rect2(r.position+Vector2(390,18),Vector2(165,68)),Color("#554431"))
		draw_string(ThemeDB.fallback_font,r.position+Vector2(390,58),"ПЕРЕЛОЖИТЬ ВСЁ",HORIZONTAL_ALIGNMENT_CENTER,165,13,Color.WHITE)

	var stored: int = factory_stored_units(selected_factory)
	var value: int = factory_stored_value(selected_factory)
	draw_string(ThemeDB.fallback_font,Vector2(80,650),"На складе: "+str(stored)+" ед.  •  будущая выплата: "+str(value)+" мон.",HORIZONTAL_ALIGNMENT_LEFT,560,18,Color("#e5d8ae"))

	if factory_processing(selected_factory):
		draw_menu_button(factory_start_rect(),"ПЕРЕРАБОТКА • "+str(factory_seconds_left(selected_factory))+" сек.")
	else:
		draw_menu_button(factory_start_rect(),"ЗАПУСТИТЬ ПЕРЕРАБОТКУ")

	var ready_money: int = int(factory_ready_balance[selected_factory])
	if ready_money > 0:
		draw_menu_button(factory_claim_rect(),"ЗАБРАТЬ "+str(ready_money)+" МОНЕТ")
	elif factory_processing(selected_factory):
		draw_menu_button(factory_claim_rect(),"ПАРТИЯ ЕЩЁ НЕ ГОТОВА")
	else:
		draw_menu_button(factory_claim_rect(),"ГОТОВОЙ ВЫПЛАТЫ НЕТ")

	draw_menu_button(back_rect(),"НАЗАД")
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(55,915),message,HORIZONTAL_ALIGNMENT_CENTER,610,17,Color.WHITE)

func draw_rail(pos: Vector2i) -> void:
	var c: Vector2 = tile_pos(pos.x,pos.y)+Vector2(TILE*0.5,TILE*0.5)
	var neighbors: Array[Vector2i] = rail_neighbors(pos)
	var metal: Color = Color("#8e969a")
	var sleeper: Color = Color("#684b35")

	# Sleepers.
	draw_rect(Rect2(c+Vector2(-22,-14),Vector2(44,5)),sleeper)
	draw_rect(Rect2(c+Vector2(-22,-2),Vector2(44,5)),sleeper)
	draw_rect(Rect2(c+Vector2(-22,10),Vector2(44,5)),sleeper)

	var horizontal: bool = neighbors.has(Vector2i.LEFT) or neighbors.has(Vector2i.RIGHT)
	var vertical: bool = neighbors.has(Vector2i.UP) or neighbors.has(Vector2i.DOWN)
	if horizontal or not vertical:
		draw_line(c+Vector2(-25,-8),c+Vector2(25,-8),metal,4.0)
		draw_line(c+Vector2(-25,8),c+Vector2(25,8),metal,4.0)
	if vertical:
		draw_line(c+Vector2(-8,-25),c+Vector2(-8,25),metal,4.0)
		draw_line(c+Vector2(8,-25),c+Vector2(8,25),metal,4.0)

func draw_unload_station(pos: Vector2i) -> void:
	var c: Vector2 = tile_pos(pos.x,pos.y)+Vector2(TILE*0.5,TILE*0.5)
	var connected: bool = rail_connected_to_surface(pos)
	draw_rect(Rect2(c+Vector2(-23,-20),Vector2(46,36)),Color("#555b60"))
	draw_rect(Rect2(c+Vector2(-18,-15),Vector2(36,20)),Color("#2c3235"))
	draw_rect(Rect2(c+Vector2(-25,12),Vector2(50,7)),Color("#8a633e"))
	draw_circle(c+Vector2(17,-13),5,Color("#62cf78") if connected else Color("#c4534f"))
	draw_string(ThemeDB.fallback_font,c+Vector2(-25,30),"ВЫГРУЗКА",HORIZONTAL_ALIGNMENT_CENTER,50,8,Color("#d7dcdf"))

func draw_logistics() -> void:
	draw_screen_bg("ШАХТНАЯ ЛОГИСТИКА")
	draw_string(ThemeDB.fallback_font,Vector2(60,145),"Строй пункт выгрузки и соединяй его рельсами с поверхностью.",HORIZONTAL_ALIGNMENT_CENTER,600,16,Color("#c7ced3"))
	draw_string(ThemeDB.fallback_font,Vector2(60,178),"Руда сама отправится на нужный завод. Деньги забираются наверху.",HORIZONTAL_ALIGNMENT_CENTER,600,15,Color("#d9c587"))

	var here_station: bool = unload_stations.has(player)
	var connected: bool = here_station and rail_connected_to_surface(player)
	var status: String = "Нет пункта выгрузки в этой клетке"
	if here_station:
		status = "Линия до поверхности: " + ("ПОДКЛЮЧЕНА" if connected else "НЕ ПОДКЛЮЧЕНА")
	draw_string(ThemeDB.fallback_font,Vector2(70,260),status,HORIZONTAL_ALIGNMENT_LEFT,580,20,Color("#65cf7b") if connected else Color("#e0a458"))

	draw_menu_button(logistics_station_rect(),("ПУНКТ УЖЕ ПОСТРОЕН" if here_station else "ПОСТРОИТЬ ПУНКТ ВЫГРУЗКИ • "+str(UNLOAD_STATION_COST)))
	draw_menu_button(logistics_rail_rect(),("РЕЛЬСЫ УЖЕ ЛЕЖАТ" if rail_tiles.has(player) else "ПРОЛОЖИТЬ РЕЛЬС • "+str(RAIL_COST)))
	draw_menu_button(logistics_unload_rect(),"ВЫГРУЗИТЬ РЮКЗАК В ВАГОНЕТКУ")

	draw_string(ThemeDB.fallback_font,Vector2(90,705),"В рюкзаке: "+str(bag_used())+"/"+str(bag_capacity()),HORIZONTAL_ALIGNMENT_LEFT,540,18,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(90,740),"Рельс построено: "+str(rail_tiles.size())+" секций",HORIZONTAL_ALIGNMENT_LEFT,540,16,Color("#c5ccd0"))
	draw_string(ThemeDB.fallback_font,Vector2(90,770),"Цена секции: "+str(RAIL_COST)+" мон. • пункт выгрузки: "+str(UNLOAD_STATION_COST)+" мон.",HORIZONTAL_ALIGNMENT_LEFT,540,15,Color("#d8b96d"))

	draw_menu_button(back_rect(),"НАЗАД")
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(55,845),message,HORIZONTAL_ALIGNMENT_CENTER,610,17,Color.WHITE)

func draw_hazard(r: Rect2, kind: String) -> void:
	if kind == "lava":
		draw_rect(r,Color("#ad2d1e"))
		draw_rect(Rect2(r.position+Vector2(0,9),Vector2(r.size.x,8)),Color("#f27225"))
		draw_circle(r.position+Vector2(17,32),5,Color("#ffd05a"))
	elif kind == "spikes":
		draw_colored_polygon(PackedVector2Array([
			r.position+Vector2(3,r.size.y),r.position+Vector2(14,16),
			r.position+Vector2(26,r.size.y),r.position+Vector2(39,15),
			r.position+Vector2(50,r.size.y)
		]),Color("#a9b2ba"))
	else:
		draw_colored_polygon(PackedVector2Array([
			r.position+Vector2(8,46),r.position+Vector2(18,11),
			r.position+Vector2(29,46),r.position+Vector2(38,19),
			r.position+Vector2(48,46)
		]),Color("#747bea"))

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
	draw_shop_card(shop_torch_rect(),"Факел x"+str(torch_count),"Постоянный свет в расчищенном тоннеле",torch_price())
	draw_shop_card(shop_battery_rect(),"Аккумулятор "+str(battery_capacity),"Больше времени работы фонаря",battery_upgrade_price())
	draw_menu_button(back_rect(),"НАЗАД")
	if message_time > 0.0:
		draw_string(ThemeDB.fallback_font,Vector2(55,1015),message,HORIZONTAL_ALIGNMENT_CENTER,610,18,Color.WHITE)

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
	draw_rect(r,Color("#29372f"))
	draw_rect(r.grow(-4),Color("#56695d"),false,3)
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
