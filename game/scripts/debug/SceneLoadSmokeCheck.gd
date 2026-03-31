extends SceneTree

func _init() -> void:
	var exit_code_: int = 0
	var scene_paths_ := OS.get_cmdline_user_args()
	if scene_paths_.is_empty():
		printerr("[SceneSmoke] Missing scene paths")
		quit(1)
		return

	for scene_path_ in scene_paths_:
		var scene_resource_ := load(String(scene_path_))
		if scene_resource_ == null:
			printerr("[SceneSmoke] Failed to load %s" % scene_path_)
			exit_code_ = 1
			continue

		print("[SceneSmoke] Loaded %s" % scene_path_)

	quit(exit_code_)
