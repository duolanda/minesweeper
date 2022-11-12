class_name TileData

#位置
var position:Vector2 = Vector2.ZERO;
#是否是雷
var isMine:bool = false;
#是否已经开启
var opened:bool = false;
#是否插旗
var flaged:bool = false;
#周围格子的雷的数量
var aroundMine:int = 0;
