# Asset conversion only: resize the generated master for Android resources.
# The game itself runs in Unreal; this offline converter has no runtime dependency.
extends SceneTree
func _initialize():
	var root = ProjectSettings.globalize_path(get_script().resource_path).get_base_dir().path_join("../..").simplify_path()
	var source = root.path_join("design/icon-094/launcher-source.png")
	var output = root.path_join("unreal/WaitingForDawn/Build/Android/res/")
	var master = Image.load_from_file(source)
	assert(master != null and master.get_width() == master.get_height())
	for item in [["drawable", 128], ["drawable-ldpi", 36], ["drawable-mdpi", 48], ["drawable-hdpi", 72], ["drawable-xhdpi", 96], ["drawable-xxhdpi", 144], ["drawable-xxxhdpi", 192]]:
		var image = master.duplicate()
		image.resize(item[1], item[1], Image.INTERPOLATE_LANCZOS)
		var directory = output + item[0]
		DirAccess.make_dir_recursive_absolute(directory)
		assert(image.save_png(directory + "/icon.png") == OK)
	var adaptive = master.duplicate()
	adaptive.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(output + "drawable-nodpi")
	assert(adaptive.save_png(output + "drawable-nodpi/wfd_launcher_art.png") == OK)
	print("Waiting for Dawn 0.9.4 launcher artwork exported at all seven densities and adaptive resolution")
	quit()
