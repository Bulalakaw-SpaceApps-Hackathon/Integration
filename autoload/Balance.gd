extends Node
## Loads res://data/balance.tres. Falls back to the script defaults if the file is missing.

const PATH := "res://data/balance.tres"
var config: BalanceConfig


func _ready() -> void:
	if ResourceLoader.exists(PATH):
		config = load(PATH)
	if config == null:
		push_warning("balance.tres missing, using BalanceConfig defaults")
		config = BalanceConfig.new()
