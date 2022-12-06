extends WindowDialog

onready var widthLE:LineEdit = $GridContainer/WidthLineEdit
onready var heightLE:LineEdit = $GridContainer/HeightLineEdit
onready var mineLE:LineEdit = $GridContainer/MineLineEdit



func _ready():
	pass # Replace with function body.



func _on_Main_current_set(width, height, mine):
	widthLE.text = str(width);
	heightLE.text = str(height);
	mineLE.text = str(mine);
	
