class_name GameSettings extends RefCounted

const PATH : String = "user://settings.cfg"

static var fullscreen : bool = false
static var vsync : bool = true
static var volume : int = 80 # 0 - 100

static func load_settings() -> void:
	var cfg : ConfigFile = ConfigFile.new()
	if cfg.load( PATH ) == OK:
		fullscreen = cfg.get_value( "video", "fullscreen", fullscreen )
		vsync = cfg.get_value( "video", "vsync", vsync )
		volume = clampi( cfg.get_value( "audio", "volume", volume ), 0, 100 )
	apply()

static func apply() -> void:
	DisplayServer.window_set_mode( DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED )
	DisplayServer.window_set_vsync_mode( DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED )
	AudioServer.set_bus_volume_db( 0, linear_to_db( maxf( volume / 100.0, 0.0001 ) ) )

static func save() -> void:
	var cfg : ConfigFile = ConfigFile.new()
	cfg.set_value( "video", "fullscreen", fullscreen )
	cfg.set_value( "video", "vsync", vsync )
	cfg.set_value( "audio", "volume", volume )
	cfg.save( PATH )
