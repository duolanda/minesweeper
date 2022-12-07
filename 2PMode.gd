extends Node2D

var reset_normal = preload("res://assets/images/reset_normal.png");
var reset_pressed = preload("res://assets/images/reset_pressed.png");
var gameover_normal = preload("res://assets/images/gameover_normal.png");
var gameover_pressed = preload("res://assets/images/gameover_pressed.png");
var happy_normal = preload("res://assets/images/happy_normal.png");
var happy_pressed = preload("res://assets/images/happy_pressed.png")
var clicked_normal = preload("res://assets/images/clicked_normal.png")

#查找规则（统计格子周围哪几个格子有雷）
const RULE:Array = [Vector2(-1,-1),Vector2(-1,0),Vector2(-1,1),Vector2(0,-1),Vector2(0,1),Vector2(1,-1),Vector2(1,0),Vector2(1,1)];
# 边距
const LEFT_MARGIN:int = 11;
const RIGHT_MARGIN:int = 11;
const TOP_MARGIN:int = 71;
const BOTTOM_MARGIN:int=11;
#格子的大小
const TILE_SIZE:int = 32;
#没标记的雷
const UNFLAG_MINE_POSITION:Vector2 = Vector2(5,1); #tile是二维数组
#0-8的数字
const NUM0_POSITION:Vector2 = Vector2(0,0); 
const NUM1_POSITION:Vector2 = Vector2(1,0); 
const NUM2_POSITION:Vector2 = Vector2(2,0); 
const NUM3_POSITION:Vector2 = Vector2(3,0); 
const NUM4_POSITION:Vector2 = Vector2(4,0); 
const NUM5_POSITION:Vector2 = Vector2(5,0); 
const NUM6_POSITION:Vector2 = Vector2(6,0); 
const NUM7_POSITION:Vector2 = Vector2(0,1); 
const NUM8_POSITION:Vector2 = Vector2(1,1); 
#默认显示
const NORMAL_POSITION:Vector2 = Vector2(2,1);
#旗子
const RED_FLAG_POSITION:Vector2 = Vector2(3,1);
#旗子
const BLUE_FLAG_POSITION:Vector2 = Vector2(0,2);
#被点击的雷
const CLICK_MINE_POSITION:Vector2 = Vector2(6,1);
#标记错的雷
const WRONG_FLAG_MINE_POSITION:Vector2 = Vector2(4,1);


onready var bg:NinePatchRect = $Game/BG;
onready var game:Node2D = $Game;
onready var gui:Control = $Game/GUI;
onready var redLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/redBG/redLabel;
onready var blueLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/blueBG/blueLabel;
onready var remainLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/CenterContainer/remainBG/remainLabel;
onready var tilemap:TileMap = $Game/TileMap;
onready var menuButton:MenuButton = $Game/GUI/MenuButton;
onready var CongratulateDialog:AcceptDialog = $Game/CongratulateDialog;

signal current_set(width, height, mine);

#格子的横向数量
var gridWidth:int = 16;
#格子的纵向数量
var gridHeight:int = 16;
#地雷的数量
var totalMineCount:int = 51;
#全部格子
var totalsTiles:Array = [];
#队列
var search_queue:Array = [];
#剩余雷的数量
var remainMine:int = 0;
#红旗数量
var redFlag:int = 0;
#蓝旗数量
var blueFlag:int = 0;
#是否胜利
var isWin:bool = false;
#旗子颜色
var flag_color:int = 1;

func _ready() -> void:	
	init_map();
	init_game();
	draw_tiles();

func _input(event:InputEvent) -> void:
	if menuButton.get_popup().visible or isWin:
		return
		
	if event is InputEventMouseButton and not event.pressed and event.button_index == BUTTON_LEFT:
		mouse_left_click(event.position);
			



func init_map():
	var width:int = LEFT_MARGIN + gridWidth * TILE_SIZE + RIGHT_MARGIN;
	var height:int = TOP_MARGIN + gridHeight * TILE_SIZE + BOTTOM_MARGIN;
	bg.rect_size = Vector2(width, height);
	gui.rect_size.x = width;
	OS.set_window_size(Vector2(width, height))



func init_game():
	#全部的数据数量
	var totalCount:int = gridWidth*gridHeight;
	var tempMineCount:int = totalMineCount;
	var totals:Array = [];
	search_queue = []
	
	#弹出菜单
	var popup = menuButton.get_popup();
	popup.connect("id_pressed", self, "game_menu");
	
	for i in totalCount:
		if tempMineCount >  0:
			totals.append("mine");
			tempMineCount -= 1;
		else:
			totals.append("empty");
	randomize();
	totals.shuffle();
	
	# 将随机好的雷和格子加进来
	totalsTiles = [];
	var index:int = 0;
	for y in gridHeight:
		for x in gridWidth:
			var tile:TileData = TileData.new();
			tile.position = Vector2(x,y);
			if totals[index] == "mine":
				tile.isMine = true;
			else:
				tile.isMine = false;
			tile.flaged = false;
			tile.opened = false;
			tile.aroundMine = 0;
			totalsTiles.append(tile);
			index += 1;
	index = 0;
	
	#计算单个格子周围的雷的数量
	for tile in totalsTiles:
		if tile.isMine == false:
			tile.aroundMine = get_mine_count(tile.position);
			
	remainMine = totalMineCount;
	remainLabel.text = "%02d" % remainMine;
	redLabel.text = "%02d" % redFlag;
	blueLabel.text = "%02d" % blueFlag;

func mouse_left_click(mouse_position:Vector2):
	var local_position:Vector2 = tilemap.to_local(mouse_position);
	var map_position:Vector2 = tilemap.world_to_map(local_position);
	if map_position.x < 0 or map_position.x >= gridWidth or map_position.y < 0 or map_position.y >= gridHeight:
		return;
	
	var index:int = map_position.y * gridWidth + map_position.x;
	var tile:TileData = totalsTiles[index];
	if tile.flaged:
			return

	if not tile.opened:
		if tile.isMine:
			tile.flaged = true;
			remainMine -= 1;
			remainLabel.text = "%02d" % remainMine;
			if flag_color == 1:
				redFlag += 1;
				redLabel.text = "%02d" % redFlag;
			else:
				blueFlag += 1;
				blueLabel.text = "%02d" % blueFlag;
			draw_single_tile(tile);
			check_win()
		else:
			tile.opened = true;
			draw_single_tile(tile);
			if tile.aroundMine == 0:
				search_queue = search_around(tile.position);
				while search_queue.size() > 0:
					check_tile(search_queue.pop_front());	
			# 没点到雷就变换颜色
			flag_color = -flag_color;


func check_tile(tile:TileData):
	tile.opened = true;
	draw_single_tile(tile);
	if tile.aroundMine == 0:
		var next_queue:Array = search_around(tile.position);
		var is_have:bool = false;
		for n_tile in next_queue:
			is_have = false;
			for s_tile in search_queue:
				if s_tile.position == n_tile.position:
					is_have = true;
					break;
			if not is_have:
				search_queue.append(n_tile);
				

func get_flaged_count(tile_pos:Vector2) -> int:
	var flagedCount:int = 0;
	for r in RULE:
		var search_position:Vector2 = Vector2(r.x+tile_pos.x, r.y+tile_pos.y);
		if search_position.x < 0 or search_position.x >= gridWidth or search_position.y < 0 or search_position.y >= gridHeight:
			continue;
		#寻找的格子在数组里相对当前格子的偏移量
		var search_offset_int = r.y * gridWidth + r.x; 
		#当前格子在数组里的位置
		var currentIndex:int = tile_pos.y * gridWidth +tile_pos.x;
		#目标格子位置
		var searchIndex:int = currentIndex + search_offset_int;
		var searchTile:TileData = totalsTiles[searchIndex];
		
		if not searchTile.opened and searchTile.flaged:
			flagedCount += 1;
	return flagedCount;

#返回不包含打开的、旗子和雷大于1的格子
func search_around(tile_pos:Vector2, has_mine:bool = false) -> Array:
	var arr:Array = [];
	for r in RULE:
		var search_position:Vector2 = Vector2(r.x+tile_pos.x, r.y+tile_pos.y);
		if search_position.x < 0 or search_position.x >= gridWidth or search_position.y < 0 or search_position.y >= gridHeight:
			continue;
		#寻找的格子在数组里相对当前格子的偏移量
		var search_offset_int = r.y * gridWidth + r.x; 
		#当前格子在数组里的位置
		var currentIndex:int = tile_pos.y * gridWidth +tile_pos.x;
		#目标格子位置
		var searchIndex:int = currentIndex + search_offset_int;
		var searchTile:TileData = totalsTiles[searchIndex];
		if not searchTile.opened and not searchTile.flaged:
			if has_mine == false:
				if not searchTile.isMine:
					arr.append(searchTile);
			else:
				arr.append(searchTile);
		
	return arr;

func draw_single_tile(tile:TileData):
	if tile.opened:
		var style_position:Vector2;
		match tile.aroundMine:
			0:
				style_position = NUM0_POSITION;
			1:
				style_position = NUM1_POSITION;
			2:
				style_position = NUM2_POSITION;
			3:
				style_position = NUM3_POSITION;
			4:
				style_position = NUM4_POSITION;
			5:
				style_position = NUM5_POSITION;
			6:
				style_position = NUM6_POSITION;
			7:
				style_position = NUM7_POSITION;
			8:
				style_position = NUM8_POSITION;	
		set_cell(tile.position.x, tile.position.y, style_position);
	elif tile.flaged:
		if flag_color == 1:
			set_cell(tile.position.x, tile.position.y, RED_FLAG_POSITION);
		else:
			set_cell(tile.position.x, tile.position.y, BLUE_FLAG_POSITION);
	else:
		set_cell(tile.position.x, tile.position.y, NORMAL_POSITION);

#胜利
func check_win():
	if redFlag == 26:
		isWin = true;
		CongratulateDialog.dialog_text = "红方胜利！"
		CongratulateDialog.popup_centered();
		
	if blueFlag == 26:
		isWin = true;
		CongratulateDialog.dialog_text = "蓝方胜利！"
		CongratulateDialog.popup_centered();
		

#获取周围的雷的数量
func get_mine_count(tile_pos:Vector2):
	var mineCount:int = 0;
	for r in RULE:
		var search_position:Vector2 = Vector2(r.x+tile_pos.x, r.y+tile_pos.y);
		if search_position.x < 0 or search_position.x >= gridWidth or search_position.y < 0 or search_position.y >= gridHeight:
			continue;
		#寻找的格子在数组里相对当前格子的偏移量
		var search_offset_int = r.y * gridWidth + r.x; 
		#当前格子在数组里的位置
		var currentIndex:int = tile_pos.y * gridWidth +tile_pos.x;
		#目标个字位置
		var searchIndex:int = currentIndex + search_offset_int;
		
		if totalsTiles[searchIndex].isMine:
			mineCount += 1;
			
	return mineCount; 
	
func draw_tiles():
	for tile in totalsTiles:
		set_cell(tile.position.x, tile.position.y, NORMAL_POSITION);


func reset():
	isWin = false;
	redFlag = 0;
	blueFlag = 0;
	
	init_game();
	draw_tiles();
		
func set_cell(x:int, y:int, style:Vector2):
	tilemap.set_cell(x, y, 0, false, false, false, style);

#游戏菜单
func game_menu(id):
	match id:
		0:
			reset();
		1:
			get_tree().change_scene("res://Main.tscn");
