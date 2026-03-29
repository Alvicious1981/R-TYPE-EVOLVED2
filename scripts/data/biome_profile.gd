class_name BiomeProfile
extends Resource

## Perfil de datos para un bioma. Controla el aspecto visual del nivel. (TDD §1.1)

@export var biome_id: String = ""
@export var background_texture: Texture2D
@export var parallax_layers: Array[Texture2D] = []
@export var accent_color: Color = Color.WHITE
@export var music_track: AudioStream
