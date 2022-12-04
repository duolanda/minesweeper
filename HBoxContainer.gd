extends HBoxContainer


const MenuKey = {
	"MenuName": "menu_name",
	'ScanCode': "scancode",
	"Control" : 'control',
	"Command" : 'Command',
	"Shift": "shift",
	"Alt": "alt",
}

## 通过添加修改下面的数据进行添加菜单
const MenuData = {
	"File": [
		{
			MenuKey.MenuName: "Open Project",	# 菜单子项的名称
			MenuKey.ScanCode: KEY_O,	# 需要字符 O
			MenuKey.Control: true,		# 需要ctrl 键
		},
		{MenuKey.MenuName: "---"},		# 开头为 --- 的为分隔符
		{
			MenuKey.MenuName: "Exit",
			MenuKey.ScanCode: KEY_E,
			MenuKey.Control: true,
		},
	],
	"Edit": [
		{
			MenuKey.MenuName: "Undo",
			MenuKey.ScanCode: KEY_Z,
			MenuKey.Control: true,
		},
	]
}


func _ready():
	# 添加菜单按钮
	for menu_name in MenuData.keys():
		var menu = MenuButton.new()
		menu.switch_on_hover = true
		menu.text = menu_name
		add_child(menu)
		# 遍历菜单数据
		var popup := menu.get_popup() as PopupMenu
		var idx := -1
		for item_data in MenuData[menu_name]:
			idx += 1
			# 菜单名
			var item_name := item_data[MenuKey.MenuName] as String
			# 添加分隔符
			if item_name.begins_with('---'):
				popup.add_separator(item_name.right(3))
				continue
			# 添加菜单项
			popup.add_item(item_name)
			# 设置菜单快捷键
			var shortcut = ShortCut.new()
			var input = InputEventKey.new()
			shortcut.shortcut = input
			if item_data.has(MenuKey.ScanCode):
				input.scancode = item_data[MenuKey.ScanCode]
			if item_data.has(MenuKey.Control):
				input.control = item_data[MenuKey.Control]
			if item_data.has(MenuKey.Command):
				input.command = item_data[MenuKey.Command]
			if item_data.has(MenuKey.Alt):
				input.alt = item_data[MenuKey.Alt]
			if item_data.has(MenuKey.Shift):
				input.shift = item_data[MenuKey.Shift]
			popup.set_item_shortcut(idx, shortcut)
		popup.connect("index_pressed", self, "_menu_index_pressed", [menu_name])


## 按下菜单项
func _menu_index_pressed(idx: int, menu_name: String) -> void:
	
	# 对应菜单的数据列表
	var menu_data := MenuData[menu_name] as Array
	# 对应菜单项的数据
	var item_data := menu_data[idx] as Dictionary
	# 菜单名
	var item_name := item_data[MenuKey.MenuName] as String
	
	print('按下 %s 菜单的 %s 项' % [menu_name, item_name])
	
	# 根据 item_name 执行功能
	# 例：
	match item_name:
		'Open Project':
			pass
		'Exit':
			get_tree().quit()
