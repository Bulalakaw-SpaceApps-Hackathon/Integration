class_name CodexEntry
extends Resource
## One Codex page: an icon, two short sentences, one source line. Unlocked by winning nights.

@export var id: String = ""
@export var title: String = ""
@export_multiline var text: String = ""          ## exactly two short sentences
@export var real_number: String = ""             ## optional real figure, e.g. "8,100 microgray"
@export var source: String = ""
@export_enum("real", "simplified") var badge: String = "real"
@export var order: int = 0
