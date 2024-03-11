@tool
extends EditorPlugin

class ComicEditorDebuggerPlugin extends EditorDebuggerPlugin:
	var fs:EditorFileSystem

	func _init(fs:EditorFileSystem):
		self.fs = fs

	func _has_capture(prefix):
		return prefix == "icbm"

	func _capture(message, data, session_id):
		if message == "icbm:scan":
			fs.scan()
			fs.get_window().mode = Window.MODE_MINIMIZED
		if message == "icbm:is_scan_complete":
			if not fs.is_scanning():
				get_session(session_id).send_message("icbm:scan_complete", [])

	func _setup_session(session_id):
		# Add a new tab in the debugger session UI containing a label.
		var label = Label.new()
		label.name = "ICBM Debugger"
		label.text = "ICBM Debugger"
		var session = get_session(session_id)
		# Listens to the session started and stopped signals.
		session.started.connect(func (): print("Session started"))
		session.stopped.connect(func (): print("Session stopped"))
		session.add_session_tab(label)

var debugger = ComicEditorDebuggerPlugin.new(get_editor_interface().get_resource_filesystem())

func _enter_tree():
	add_debugger_plugin(debugger)

func _exit_tree():
	remove_debugger_plugin(debugger)
