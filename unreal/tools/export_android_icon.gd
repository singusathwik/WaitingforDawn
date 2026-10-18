# Asset conversion only: rasterize the existing original SVG for Android resources.
# The game itself runs in Unreal; this offline converter has no runtime dependency.
extends SceneTree
func _initialize():
	var source = "C:/Users/Sathwik/Downloads/HorrorGame/icon.svg"
	var output = "C:/Users/Sathwik/Downloads/HorrorGame/unreal/WaitingForDawn/Build/Android/res/"
	for item in [["drawable", 128], ["drawable-ldpi", 36], ["drawable-mdpi", 48], ["drawable-hdpi", 72], ["drawable-xhdpi", 96], ["drawable-xxhdpi", 144], ["drawable-xxxhdpi", 192]]:
		var image = Image.new()
		assert(image.load_svg_from_string(FileAccess.get_file_as_string(source), float(item[1]) / 256.0) == OK)
		var directory = output + item[0]
		DirAccess.make_dir_recursive_absolute(directory)
		assert(image.save_png(directory + "/icon.png") == OK)
	print("Original Waiting for Dawn icon rasterized for Android")
	quit()
