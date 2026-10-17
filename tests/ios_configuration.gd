extends SceneTree

func _initialize():
	var game = load("res://game.gd").new()
	assert(game._is_mobile("iOS"))
	assert(game._is_mobile("Android"))
	assert(not game._is_mobile("Windows"))
	assert(not game._is_mobile("macOS"))
	game.free()
	var config = ConfigFile.new()
	assert(config.load("res://export_presets.cfg") == OK)
	assert(config.get_value("preset.2", "platform") == "iOS")
	assert(config.get_value("preset.2.options", "architectures/arm64"))
	assert(config.get_value("preset.2.options", "application/export_project_only"))
	var xml = XMLParser.new()
	var content = config.get_value("preset.2.options", "application/additional_plist_content")
	assert(content.contains("NSLocalNetworkUsageDescription"))
	assert(xml.open_buffer(("<plist><dict>" + content + "</dict></plist>").to_utf8_buffer()) == OK)
	var result = xml.read()
	while result == OK:
		result = xml.read()
	assert(result == ERR_FILE_EOF)
	print("PASS: mobile platform routing, iOS export configuration and permission plist XML (not iOS runtime testing).")
	quit()
