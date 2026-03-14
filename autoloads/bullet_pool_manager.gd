class_name BulletPoolManager
extends Node

# Bullet class will be typed Array[Bullet] once the Bullet scene/class is defined.
# Using Array[Node] as intermediate strict type during bootstrap.
const POOL_SIZE: int = 2000
var _available: Array[Node] = []
var _active: Array[Node] = []
