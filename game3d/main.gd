extends Node3D

const MobileHUD = preload("res://mobile_hud.gd")

const BLOCK_SIZE: float = 1.4
const MOVE_SPEED: float = 3.8
const GRAVITY: float = 18.0
const MINE_RANGE: float = 2.55
const BATTERY_DRAIN_PER_SECOND: float = 0.48
const SURFACE_RECHARGE_PER_SECOND: float = 30.0

var rng := RandomNumberGenerator.new()
var player: CharacterBody3D
var camera: Camera3D
var headlamp: SpotLight3D
var hud: Control

var move_input: Vector2 = Vector2.ZERO
var flashlight_on: bool = true
var battery: float = 100.0
var torch_count: int = 4
var coins: int = 5000
var inventory: Dictionary = {"coal":0,"iron":0,"gold":0,"diamond":0}
var blocks: Dictionary = {}
var mine_cooldown: float = 0.0
var status_text: String = "Спускайся в шахту и разбивай породу"
var status_timer: float = 5.0

func _ready() -> void:
	rng.randomize()
	create_environment()
	create_floor_and_bounds()
	create_player()
	create_mine()
	create_surface_station()
	create_hud()

func create_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#080a0c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#52606a")
	env.ambient_light_energy = 0.12
	env.fog_enabled = true
	env.fog_light_color = Color("#101318")
	env.fog_density = 0.018
	world_env.environment = env
	add_child(world_env)

func create_floor_and_bounds() -> void:
	create_static_box(Vector3(18.0,0.5,46.0),Vector3(0,-0.25,-13.0),Color("#25282a"))
	create_static_box(Vector3(0.6,3.4,46.0),Vector3(-8.5,1.45,-13.0),Color("#393532"))
	create_static_box(Vector3(0.6,3.4,46.0),Vector3(8.5,1.45,-13.0),Color("#393532"))

func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Miner"
	player.position = Vector3(0,1.0,3.2)
	add_child(player)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.75
	collision.shape = capsule
	player.add_child(collision)

	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.62,0.82,0.38)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0,0.15,0)
	body_mesh.material_override = make_material(Color("#315a72"))
	player.add_child(body_mesh)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	head.mesh = sphere
	head.position = Vector3(0,0.84,0)
	head.material_override = make_material(Color("#d0a06f"))
	player.add_child(head)

	var helmet := MeshInstance3D.new()
	var helmet_mesh := CylinderMesh.new()
	helmet_mesh.top_radius = 0.31
	helmet_mesh.bottom_radius = 0.31
	helmet_mesh.height = 0.18
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0,1.08,0)
	helmet.material_override = make_material(Color("#d9a83e"))
	player.add_child(helmet)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 66.0
	add_child(camera)
	camera.global_position = player.global_position + Vector3(0,2.8,5.8)
	camera.look_at(player.global_position + Vector3(0,0.8,0),Vector3.UP)

	headlamp = SpotLight3D.new()
	headlamp.spot_range = 13.0
	headlamp.spot_angle = 42.0
	headlamp.light_energy = 5.0
	headlamp.light_color = Color("#fff2cb")
	headlamp.shadow_enabled = false
	camera.add_child(headlamp)
	headlamp.position = Vector3(0,0,-0.05)

func create_surface_station() -> void:
	var pad := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(5.0,0.15,3.5)
	pad.mesh = mesh
	pad.position = Vector3(0,0.08,3.1)
	pad.material_override = make_material(Color("#4e5559"))
	add_child(pad)

	var entrance_light := OmniLight3D.new()
	entrance_light.position = Vector3(0,2.6,2.0)
	entrance_light.omni_range = 8.0
	entrance_light.light_energy = 2.4
	entrance_light.light_color = Color("#f2d28a")
	add_child(entrance_light)

func create_mine() -> void:
	for z in range(-3,-25,-1):
		for x in range(-5,6):
			if z >= -6 and abs(x) <= 1:
				continue
			if z < -7 and abs(x) <= 3 and rng.randf() < 0.09:
				continue
			var kind: String = roll_block_kind(-z)
			add_block(Vector2i(x,z),kind,block_hp(kind))

func roll_block_kind(depth: int) -> String:
	var r: float = rng.randf()
	if depth < 8:
		if r < 0.20:
			return "coal"
		return "stone"
	if depth < 15:
		if r < 0.13:
			return "iron"
		if r < 0.20:
			return "coal"
		return "stone"
	if depth < 21:
		if r < 0.10:
			return "gold"
		if r < 0.20:
			return "iron"
		return "stone"
	if r < 0.08:
		return "diamond"
	if r < 0.18:
		return "gold"
	if r < 0.28:
		return "iron"
	return "stone"

func block_hp(kind: String) -> int:
	match kind:
		"coal":
			return 1
		"iron":
			return 2
		"gold":
			return 3
		"diamond":
			return 4
		_:
			return 2

func add_block(grid: Vector2i, kind: String, hp: int) -> void:
	var body := StaticBody3D.new()
	body.name = "Block_"+str(grid.x)+"_"+str(grid.y)
	body.position = Vector3(float(grid.x)*BLOCK_SIZE,BLOCK_SIZE*0.5,float(grid.y)*BLOCK_SIZE)
	body.add_to_group("mine_block")
	body.set_meta("hp",hp)
	body.set_meta("max_hp",hp)
	body.set_meta("kind",kind)
	body.set_meta("gx",grid.x)
	body.set_meta("gz",grid.y)

	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(BLOCK_SIZE*0.97,BLOCK_SIZE*0.97,BLOCK_SIZE*0.97)
	mesh_instance.mesh = box
	mesh_instance.material_override = make_material(Color("#55504b"))
	body.add_child(mesh_instance)

	var shape_node := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(BLOCK_SIZE*0.97,BLOCK_SIZE*0.97,BLOCK_SIZE*0.97)
	shape_node.shape = box_shape
	body.add_child(shape_node)

	if kind != "stone":
		add_ore_marks(body,kind)

	add_child(body)
	blocks[grid] = body

func add_ore_marks(parent: Node3D, kind: String) -> void:
	var color := Color("#202329")
	if kind == "iron":
		color = Color("#9c755c")
	elif kind == "gold":
		color = Color("#d6ae42")
	elif kind == "diamond":
		color = Color("#75d5e7")

	for offset in [Vector3(-0.28,0.20,0.70),Vector3(0.24,-0.08,0.70),Vector3(0.04,0.36,0.70)]:
		var mark := MeshInstance3D.new()
		var ore_mesh := SphereMesh.new()
		ore_mesh.radius = 0.10
		ore_mesh.height = 0.20
		mark.mesh = ore_mesh
		mark.position = offset
		mark.material_override = make_material(color)
		parent.add_child(mark)

func create_static_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = make_material(color)
	body.add_child(mesh_instance)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	add_child(body)

func make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	return mat

func create_hud() -> void:
	hud = MobileHUD.new()
	add_child(hud)
	hud.move_changed.connect(_on_move_changed)
	hud.mine_pressed.connect(mine_block)
	hud.torch_pressed.connect(place_torch)
	hud.flashlight_pressed.connect(toggle_flashlight)

func _on_move_changed(value: Vector2) -> void:
	move_input = value

func _physics_process(delta: float) -> void:
	if mine_cooldown > 0.0:
		mine_cooldown -= delta
	if status_timer > 0.0:
		status_timer -= delta
		if status_timer <= 0.0:
			status_text = ""

	var desired := Vector3(move_input.x,0.0,move_input.y)
	if desired.length() > 1.0:
		desired = desired.normalized()

	player.velocity.x = desired.x * MOVE_SPEED
	player.velocity.z = desired.z * MOVE_SPEED
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	else:
		player.velocity.y = -0.3

	if desired.length() > 0.08:
		var look_target: Vector3 = player.global_position + desired
		player.look_at(look_target,Vector3.UP)

	player.move_and_slide()

	var cam_target: Vector3 = player.global_position + Vector3(0,2.8,5.8)
	camera.global_position = camera.global_position.lerp(cam_target,clampf(delta*7.0,0.0,1.0))
	camera.look_at(player.global_position + Vector3(0,0.8,0),Vector3.UP)

	update_light_system(delta)
	update_hud()

func update_light_system(delta: float) -> void:
	var underground: bool = player.global_position.z < 0.5
	if underground:
		if flashlight_on and battery > 0.0:
			battery = maxf(0.0,battery-BATTERY_DRAIN_PER_SECOND*delta)
			if battery <= 0.0:
				flashlight_on = false
				show_status("Аккумулятор разряжен")
	else:
		battery = minf(100.0,battery+SURFACE_RECHARGE_PER_SECOND*delta)

	headlamp.visible = flashlight_on and battery > 0.0

func update_hud() -> void:
	if hud == null:
		return
	var total: int = 0
	for value in inventory.values():
		total += int(value)
	var depth: int = maxi(0,int(round((-player.global_position.z)/BLOCK_SIZE)))
	hud.update_status(battery,flashlight_on,torch_count,total,depth,coins,status_text)

func mine_block() -> void:
	if mine_cooldown > 0.0:
		return
	mine_cooldown = 0.23

	var origin: Vector3 = player.global_position + Vector3(0,0.85,0)
	var forward: Vector3 = -player.global_transform.basis.z.normalized()
	var query := PhysicsRayQueryParameters3D.create(origin,origin+forward*MINE_RANGE)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		show_status("Кирка не достаёт до породы")
		return

	var collider = hit.get("collider")
	if collider == null or not collider.is_in_group("mine_block"):
		show_status("Здесь нечего добывать")
		return

	var hp: int = int(collider.get_meta("hp")) - 1
	collider.set_meta("hp",hp)
	var kind: String = str(collider.get_meta("kind"))
	if hp > 0:
		var max_hp: int = int(collider.get_meta("max_hp"))
		show_status("Удар по породе • "+str(max_hp-hp)+"/"+str(max_hp))
		var mesh_node: MeshInstance3D = collider.get_child(0) as MeshInstance3D
		if mesh_node != null:
			mesh_node.scale = Vector3.ONE * (0.96 - float(max_hp-hp)*0.025)
		return

	var gx: int = int(collider.get_meta("gx"))
	var gz: int = int(collider.get_meta("gz"))
	blocks.erase(Vector2i(gx,gz))
	if inventory.has(kind):
		inventory[kind] = int(inventory[kind]) + 1
		show_status("+1 "+ore_name(kind))
	else:
		show_status("Проход расчищен")
	collider.queue_free()

func ore_name(kind: String) -> String:
	match kind:
		"coal":
			return "уголь"
		"iron":
			return "железо"
		"gold":
			return "золото"
		"diamond":
			return "алмаз"
		_:
			return kind

func toggle_flashlight() -> void:
	if not flashlight_on and battery <= 0.0:
		show_status("Аккумулятор пуст")
		return
	flashlight_on = not flashlight_on
	show_status("Фонарь "+("включён" if flashlight_on else "выключен"))

func place_torch() -> void:
	if torch_count <= 0:
		show_status("Факелы закончились")
		return
	if player.global_position.z > 0.5:
		show_status("Факел лучше поставить внутри шахты")
		return
	torch_count -= 1

	var holder := Node3D.new()
	holder.position = Vector3(player.global_position.x,0.35,player.global_position.z)
	var stick := MeshInstance3D.new()
	var stick_mesh := CylinderMesh.new()
	stick_mesh.top_radius = 0.035
	stick_mesh.bottom_radius = 0.045
	stick_mesh.height = 0.65
	stick.mesh = stick_mesh
	stick.material_override = make_material(Color("#6d452a"))
	holder.add_child(stick)

	var light := OmniLight3D.new()
	light.position = Vector3(0,0.42,0)
	light.omni_range = 5.5
	light.light_energy = 2.5
	light.light_color = Color("#ffbd68")
	holder.add_child(light)

	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.09
	flame_mesh.height = 0.18
	flame.mesh = flame_mesh
	flame.position = Vector3(0,0.40,0)
	var flame_mat := make_material(Color("#ffb347"))
	flame_mat.emission_enabled = true
	flame_mat.emission = Color("#ff9f32")
	flame_mat.emission_energy_multiplier = 2.0
	flame.material_override = flame_mat
	holder.add_child(flame)

	add_child(holder)
	show_status("Факел установлен")

func show_status(text_value: String) -> void:
	status_text = text_value
	status_timer = 2.4
