extends Node2D

var reset_normal = preload("res://assets/images/reset_normal.png");
var reset_pressed = preload("res://assets/images/reset_pressed.png");
var gameover_normal = preload("res://assets/images/gameover_normal.png");
var gameover_pressed = preload("res://assets/images/gameover_pressed.png");
var happy_normal = preload("res://assets/images/happy_normal.png");
var happy_pressed = preload("res://assets/images/happy_pressed.png")

#查找规则（统计格子周围哪几个格子有雷）
const RULE:Array = [Vector2(-1,-1),Vector2(-1,0),Vector2(-1,1),Vector2(0,-1),Vector2(0,1),Vector2(1,-1),Vector2(1,0),Vector2(1,1)];
# 边距
const LEFT_MARGIN:int = 11;
const RIGHT_MARGIN:int = 11;
const TOP_MARGIN:int = 51;
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
const NUM8_POSITION:Vector2 = Vector2(0,2); 
#默认显示
const NORMAL_POSITION:Vector2 = Vector2(2,1);
#旗子
const FLAG_POSITION:Vector2 = Vector2(3,1);
#被点击的雷
const CLICK_MINE_POSITION:Vector2 = Vector2(6,1);
#标记错的雷
const WRONG_FLAG_MINE_POSITION:Vector2 = Vector2(4,1);


onready var bg:NinePatchRect = $Game/BG;
onready var game:Node2D = $Game;
onready var gui:Control = $Game/GUI;
onready var mineLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/mineBG/mineLabel;
onready var timeLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/timeBG/timeLabel;
onready var tilemap:TileMap = $Game/TileMap;
onready var tick:Timer = $Tick;
onready var resetBtn:TextureButton = $Game/GUI/MarginContainer/HBoxContainer/CenterContainer/resetButton;

#格子的宽度
var gridWidth:int = 16;
#各自的高度
var gridHeight:int = 16;
#地雷的数量
var totalMineCount:int = 40;
#全部格子
var totalsTiles:Array = [];
#队列
var search_queue:Array = [];
#剩余雷的数量
var remainMine:int = 0;
#经过的时间
var time:int = 0;
#是否胜利
var isWinOrOver:bool = false;

func _ready() -> void:
	init_map();
	init_game();
	draw_tiles();

func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == BUTTON_LEFT and not isWinOrOver:
		mouse_left_click(event.position);
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT and not isWinOrOver:
		mouse_right_click(event.position);

func init_map():
	var width:int = LEFT_MARGIN + gridWidth * TILE_SIZE + RIGHT_MARGIN;
	var height:int = TOP_MARGIN + gridHeight * TILE_SIZE +BOTTOM_MARGIN;
	bg.rect_size = Vector2(width, height);
	
	var windowSize:Vector2 = OS.window_size;
	game.position = Vector2((windowSize.x-width)/2, (windowSize.y-height)/2)
	gui.rect_size.x = width;

func init_game():
	#全部的数据数量
	var totalCount:int = gridWidth*gridHeight;
	var tempMineCount:int = totalMineCount;
	var totals:Array = [];
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
	for y in gridWidth:
		for x in gridHeight:
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
	mineLabel.text = "%03d" % remainMine;
	time = 0
	timeLabel.text = "%03d" % time;

func mouse_left_click(mouse_position:Vector2):
	var local_position:Vector2 = tilemap.to_local(mouse_position);
	var map_position:Vector2 = tilemap.world_to_map(local_position);
	if map_position.x < 0 or map_position.x > gridWidth or map_position.y < 0 or map_position.y > gridHeight:
		return;
	
	if tick.is_stopped():
		tick.start();
		
	var index:int = map_position.y * gridWidth + map_position.x;
	var tile:TileData = totalsTiles[index];
	if not tile.opened:
		if tile.isMine:
			game_over(tile);
		else:
			tile.opened = true;
			draw_single_tile(tile);
			if tile.aroundMine == 0:
				search_queue = search_around(tile.position);
				while search_queue.size() > 0:
					check_tile(search_queue.pop_front());
			check_win()

# 当 mouse_pos 是 0 的时候是左键，1 是右键
func check_tile(tile:TileData, mouse_pos:int = 0):
	if tile.isMine == true:
		game_over(tile, mouse_pos);
	else:
		tile.opened = true;
		draw_single_tile(tile);
		if tile.aroundMine == 0:
			var next_queue:Array = search_around(tile.position);
#			search_queue.append_array(next_queue); //会重复添加
			
			var is_have:bool = false;
			for n_tile in next_queue:
				is_have = false;
				for s_tile in search_queue:
					if s_tile.position == n_tile.position:
						is_have = true;
						break;
				if not is_have:
					search_queue.append(n_tile);
				

func mouse_right_click(mouse_position:Vector2):
	var local_position:Vector2 = tilemap.to_local(mouse_position);
	var map_position:Vector2 = tilemap.world_to_map(local_position);
	if map_position.x < 0 or map_position.x > gridWidth or map_position.y < 0 or map_position.y > gridHeight:
		return;
	var index:int = map_position.y * gridWidth + map_position.x;
	var tile:TileData = totalsTiles[index];
	if not tile.opened:
		tile.flaged = not tile.flaged;
		if tile.flaged:
			remainMine -= 1;
		else:
			remainMine += 1;
		mineLabel.text = "%03d" % remainMine;
		draw_single_tile(tile);
	else: 
		#鼠标中键功能
		var flagedCount:int = get_flaged_count(map_position);
		if tile.aroundMine == flagedCount: 
			search_queue = search_around(map_position, true);
			while search_queue.size() > 0:
				check_tile(search_queue.pop_front(), 1); 
	check_win() #放在判断外层，无论是标旗还是开格子都检测

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
		#目标个字位置
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
		#目标个字位置
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
		set_cell(tile.position.x, tile.position.y, FLAG_POSITION);
	else:
		set_cell(tile.position.x, tile.position.y, NORMAL_POSITION);

#胜利
func check_win():
	if remainMine == 0:
		var unopenCount:int = 0;
		for tile in totalsTiles:
			if tile.opened == false:
				unopenCount += 1;
		if unopenCount == totalMineCount:
			isWinOrOver = true;
			if not tick.is_stopped():
				tick.stop();
			resetBtn.texture_normal = happy_normal;
			resetBtn.texture_hover = happy_normal;
			resetBtn.texture_pressed = happy_pressed;

#失败
func game_over(tile:TileData, mouse_pos:int=0):
	draw_gameover_tile(tile, mouse_pos);
	resetBtn.texture_normal = gameover_normal;
	resetBtn.texture_hover = gameover_normal;
	resetBtn.texture_pressed = gameover_pressed;
	if not tick.is_stopped():
		tick.stop();
	isWinOrOver = true;
		
#绘制失败时的格子
func draw_gameover_tile(click_tile:TileData, mouse_pos:int=0):
	for tile in totalsTiles:
		if tile == click_tile:
			if mouse_pos == 0:
				set_cell(tile.position.x, tile.position.y, CLICK_MINE_POSITION);
			else:
				set_cell(tile.position.x, tile.position.y, UNFLAG_MINE_POSITION);
		elif tile.flaged and not tile.isMine:
			set_cell(tile.position.x, tile.position.y, WRONG_FLAG_MINE_POSITION);
		elif tile.isMine:
			set_cell(tile.position.x, tile.position.y, UNFLAG_MINE_POSITION);
	

		
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
	
	
#	for tile in totalsTiles:
#		if tile.isMine:
#			set_cell(tile.position.x, tile.position.y, UNFLAG_MINE_POSITION);
#		else:
#			var style_position:Vector2;
#			match tile.aroundMine:
#				0:
#					style_position = NUM0_POSITION;
#				1:
#					style_position = NUM1_POSITION;
#				2:
#					style_position = NUM2_POSITION;
#				3:
#					style_position = NUM3_POSITION;
#				4:
#					style_position = NUM4_POSITION;
#				5:
#					style_position = NUM5_POSITION;
#				6:
#					style_position = NUM6_POSITION;
#				7:
#					style_position = NUM7_POSITION;
#				8:
#					style_position = NUM8_POSITION;	
#			set_cell(tile.position.x, tile.position.y, style_position);


func reset():
	resetBtn.texture_normal = reset_normal;
	resetBtn.texture_hover = reset_normal;
	resetBtn.texture_pressed = reset_pressed;
	isWinOrOver = false;
	init_game();
	draw_tiles();
		
func set_cell(x:int, y:int, style:Vector2):
	$Game/TileMap.set_cell(x, y, 0, false, false, false, style);
	

#计时器
func _on_Tick_timeout() -> void:
	time += 1;
	timeLabel.text = "%03d" % time;
	


func _on_resetButton_pressed() -> void:
	reset();
