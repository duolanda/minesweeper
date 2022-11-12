extends Node2D

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

onready var bg:NinePatchRect = $Game/BG;
onready var game:Node2D = $Game;
onready var gui:Control = $Game/GUI;
onready var mineLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/mineBG/mineLabel;
onready var timeLabel:Label = $Game/GUI/MarginContainer/HBoxContainer/timeBG/timeLabel;

#格子的宽度
var gridWidth:int = 16;
#各自的高度
var gridHeight:int = 16;
#地雷的数量
var totalMineCount:int = 40;
#全部格子
var totalsTiles:Array = [];


func _ready() -> void:
	init_map();
	init_game();
	draw_tiles();

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
			
func set_cell(x:int, y:int, style:Vector2):
	$Game/TileMap.set_cell(x, y, 0, false, false, false, style);
	
