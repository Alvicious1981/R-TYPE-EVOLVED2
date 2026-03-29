extends Node2D

## Controlador raíz de la escena de gameplay.
## Inicializa el bioma activo al comenzar la partida.

func _ready() -> void:
	var biome: BiomeProfile = load("res://resources/biomes/biome_nebula.tres") as BiomeProfile
	EventBus.biome_transition_requested.emit(biome)
