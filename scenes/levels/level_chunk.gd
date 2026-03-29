class_name LevelChunkNode
extends Node2D

## M22 — Chunk de nivel scrollable.
## Se mueve hacia la izquierda a scroll_speed px/s.
## Se destruye cuando sale completamente de la pantalla por la izquierda.

## Ancho del chunk en píxeles. El ChunkManager lee este valor para calcular
## cuándo generar el siguiente chunk sin huecos.
@export var chunk_width: float = 1920.0

## Velocidad de scroll en px/s (debe coincidir con SCROLL_SPEED del ChunkManager).
@export var scroll_speed: float = 100.0

## Umbral de destrucción: el chunk se elimina cuando su borde derecho sale de pantalla.
## Margen extra (-chunk_width) garantiza que ningún child visible quede colgado.
const _CULL_X: float = -1000.0


func _process(delta: float) -> void:
	position.x -= scroll_speed * delta
	# Destruir cuando el borde derecho (position.x + chunk_width) < 0
	# Usamos un margen conservador basado en chunk_width
	if position.x + chunk_width < _CULL_X:
		queue_free()
