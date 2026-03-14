class_name UpgradeData
extends Resource

## Base de datos atómica de la Tienda. Separa datos mercantiles
## de la lógica del personaje. (TDD §1.1)

@export var id: String = ""
@export var cost_scrap: int = 0
@export var icon: Texture2D
@export var stat_modifier_dict: Dictionary = {}
