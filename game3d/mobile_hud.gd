extends Control

signal move_changed(value: Vector2)
signal mine_pressed
signal torch_pressed
signal flashlight_pressed

var joystick_active: bool = false
var joystick_touch: int = -1
var joystick_vector: Vector2 = Vector2.ZERO

var battery: float = 100.0
var flashlight_on: bool = true
var torches: int = 4
var inventory_counts: Dictionary = {"coal":0,"iron":0,"gold":0,"diamond":0}
var bag_used: int = 0
var bag_capacity: int = 20
var depth_m: int = 0
var coins: int = 5000
var target_name: String = ""
var target_hp: int = 0
var target_max: int = 0
var status_text: String = "Спускайся в шахту"

const JOY_RADIUS: float = 92.0
const KNOB_RADIUS: float = 38.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	queue_redraw()

func update_status(
	new_battery: float,
	light_on: bool,
	torch_amount: int,
	new_inventory: Dictionary,
	new_bag_used: int,
	new_bag_capacity: int,
	depth: int,
	coin_amount: int,
	new_target_name: String,
	new_target_hp: int,
	new_target_max: int,
	text_value: String
) -> void:
	battery = new_battery
	flashlight_on = light_on
	torches = torch_amount
	inventory_counts = new_inventory.duplicate()
	bag_used = new_bag_used
	bag_capacity = new_bag_capacity
	depth_m = depth
	coins = coin_amount
	target_name = new_target_name
	target_hp = new_target_hp
	target_max = new_target_max
	status_text = text_value
	queue_redraw()

func joy_center() -> Vector2:
	var size: Vector2 = get_viewport_rect().size
	return Vector2(145.0, size.y - 145.0)

func mine_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size
	return Rect2(size.x - 235.0, size.y - 155.0, 205.0, 92.0)

func torch_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size
	return Rect2(size.x - 235.0, size.y - 260.0, 205.0, 78.0)

func light_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size
	return Rect2(size.x - 235.0, size.y - 352.0, 205.0, 70.0)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if mine_rect().has_point(event.position):
				mine_pressed.emit()
				get_viewport().set_input_as_handled()
				return
			if torch_rect().has_point(event.position):
				torch_pressed.emit()
				get_viewport().set_input_as_handled()
				return
			if light_rect().has_point(event.position):
				flashlight_pressed.emit()
				get_viewport().set_input_as_handled()
				return
			if event.position.distance_to(joy_center()) <= JOY_RADIUS * 1.55 and joystick_touch < 0:
				joystick_touch = event.index
				joystick_active = true
				update_joystick(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == joystick_touch:
			release_joystick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			update_joystick(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mine_rect().has_point(event.position):
				mine_pressed.emit()
				return
			if torch_rect().has_point(event.position):
				torch_pressed.emit()
				return
			if light_rect().has_point(event.position):
				flashlight_pressed.emit()
				return
			if event.position.distance_to(joy_center()) <= JOY_RADIUS * 1.55:
				joystick_touch = -2
				joystick_active = true
				update_joystick(event.position)
		elif joystick_touch == -2:
			release_joystick()
	elif event is InputEventMouseMotion and joystick_touch == -2:
		update_joystick(event.position)

func update_joystick(pos: Vector2) -> void:
	var delta: Vector2 = pos - joy_center()
	if delta.length() > JOY_RADIUS:
		delta = delta.normalized() * JOY_RADIUS
	joystick_vector = delta / JOY_RADIUS
	if joystick_vector.length() < 0.12:
		joystick_vector = Vector2.ZERO
	move_changed.emit(joystick_vector)
	queue_redraw()

func release_joystick() -> void:
	joystick_active = false
	joystick_touch = -1
	joystick_vector = Vector2.ZERO
	move_changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(0,0,size.x,62),Color(0.03,0.04,0.05,0.88))
	draw_string(ThemeDB.fallback_font,Vector2(18,25),"ШАХТЁР: ГЛУБЖЕ! 3D • v0.2",HORIZONTAL_ALIGNMENT_LEFT,520,18,Color("#f0cf69"))
	draw_string(ThemeDB.fallback_font,Vector2(18,50),"Монеты: "+str(coins)+"   Рюкзак: "+str(bag_used)+"/"+str(bag_capacity)+"   Глубина: "+str(depth_m)+" м",HORIZONTAL_ALIGNMENT_LEFT,650,15,Color.WHITE)

	draw_rect(Rect2(size.x-330,15,285,16),Color("#272a2d"))
	draw_rect(Rect2(size.x-330,15,285*clampf(battery/100.0,0.0,1.0),16),Color("#e8ca63") if flashlight_on else Color("#747474"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x-330,52),"Фонарь "+str(int(round(battery)))+"%   Факелы: "+str(torches),HORIZONTAL_ALIGNMENT_LEFT,285,14,Color.WHITE)

	var ore_text: String = "Уголь "+str(int(inventory_counts.get("coal",0)))+"  •  Железо "+str(int(inventory_counts.get("iron",0)))+"  •  Золото "+str(int(inventory_counts.get("gold",0)))+"  •  Алмазы "+str(int(inventory_counts.get("diamond",0)))
	draw_rect(Rect2(18,68,610,34),Color(0,0,0,0.48))
	draw_string(ThemeDB.fallback_font,Vector2(28,91),ore_text,HORIZONTAL_ALIGNMENT_LEFT,590,13,Color("#d7dde1"))

	if target_name != "":
		var target_text: String = "Цель: "+target_name.to_upper()
		if target_max > 0:
			target_text += "  •  прочность "+str(target_hp)+"/"+str(target_max)
		draw_rect(Rect2(size.x*0.5-250,112,500,36),Color(0.08,0.07,0.03,0.76))
		draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-235,136),target_text,HORIZONTAL_ALIGNMENT_CENTER,470,13,Color("#f0cf69"))

	if status_text != "":
		draw_rect(Rect2(size.x*0.5-270,154,540,42),Color(0,0,0,0.62))
		draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-255,181),status_text,HORIZONTAL_ALIGNMENT_CENTER,510,14,Color.WHITE)

	var jc: Vector2 = joy_center()
	draw_circle(jc,JOY_RADIUS,Color(0.05,0.07,0.06,0.74))
	draw_arc(jc,JOY_RADIUS,0,TAU,48,Color("#65736a"),4.0)
	draw_circle(jc + joystick_vector*JOY_RADIUS,KNOB_RADIUS,Color("#5c7565"))
	draw_circle(jc + joystick_vector*JOY_RADIUS-Vector2(8,8),8,Color(1,1,1,0.10))

	draw_button(mine_rect(),"КИРКА",Color("#805332"))
	draw_button(torch_rect(),"ПОСТАВИТЬ ФАКЕЛ",Color("#5b4830"))
	draw_button(light_rect(),("ВЫКЛЮЧИТЬ ФОНАРЬ" if flashlight_on else "ВКЛЮЧИТЬ ФОНАРЬ"),Color("#4e5637"))

func draw_button(r: Rect2, label: String, color: Color) -> void:
	draw_rect(r,color)
	draw_rect(r.grow(-4),color.lightened(0.12),false,3.0)
	draw_string(ThemeDB.fallback_font,r.position+Vector2(0,r.size.y*0.5+7),label,HORIZONTAL_ALIGNMENT_CENTER,r.size.x,16,Color.WHITE)
