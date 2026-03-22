# Mandato: MCP sobre edición de texto plano

Cuando el servidor `godot` MCP esté activo:
- PROHIBIDO editar `.tscn` en texto plano para mutaciones de escenas, nodos o propiedades
- Usar herramientas MCP: `create_scene`, `add_node`, `update_property`, `run_script`
- Motivo: preservar integridad de UIDs y evitar regresiones catastróficas

Cuando MCP no esté activo (Godot cerrado):
- Edición de texto plano solo para cambios estructurales planificados
- Verificar UIDs tras cualquier edición manual de .tscn
