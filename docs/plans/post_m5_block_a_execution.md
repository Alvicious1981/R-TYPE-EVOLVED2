# Post-M5 Block A — Execution Plan

**Fecha:** 2026-03-19
**Estado:** COMPLETADO Y VALIDADO — 2026-03-19
**Referencia:** `docs/plans/post_m5_stabilization_and_phase2_plan.md` §BLOQUE A

---

## Skeleton of Thought

```
Objetivo: estabilizar el vertical slice M5 sin abrir nueva funcionalidad.
  1. Documentar → este plan
  2. .gdignore → silenciar nested project warnings
  3. Null safety → BulletPoolManager guardas mínimas
  4. Huérfano → eliminar spawner.gd (verificado no instanciado)
  5. Verificaciones → autoloads, EventBus ausente
  6. Clean Floor Protocol → confirmación final
```

---

## Estado verificado pre-ejecución

| Ítem | Verificación | Resultado |
|------|-------------|-----------|
| `spawner.gd` instanciado en alguna .tscn | `grep spawner scenes/**/*.tscn` | **No encontrado** — huérfano confirmado |
| Autoloads en project.godot | Sección `[autoload]` | Solo `BulletPoolManager` — correcto |
| EventBus en project.godot o en .gd | Búsqueda global | **No existe** — no hay nada que corregir |
| `return_bullet` tiene null guard | Línea 39 de bullet_pool_manager.gd | **No** — falta `if bullet == null: return` |
| `return_enemy_bullet` tiene null guard | Línea 55 de bullet_pool_manager.gd | **No** — falta `if bullet == null: return` |

---

## Tareas del Worker (orden de ejecución)

### T1 — Crear `r-type-2/.gdignore`
- **Archivo:** `r-type-2/.gdignore`
- **Contenido:** vacío
- **Efecto:** Godot ignora la subcarpeta como proyecto anidado → desaparece el nested project warning

### T2 — Crear `valkyrie-vii-(4.4)/.gdignore`
- **Archivo:** `valkyrie-vii-(4.4)/.gdignore`
- **Contenido:** vacío
- **Efecto:** ídem para la segunda carpeta anidada

### T3 — Null safety en `BulletPoolManager.return_bullet`
- **Archivo:** `autoloads/bullet_pool_manager.gd`
- **Línea:** 39 (inicio de `return_bullet`)
- **Cambio:** añadir `if bullet == null: return` como primera línea del cuerpo

### T4 — Null safety en `BulletPoolManager.return_enemy_bullet`
- **Archivo:** `autoloads/bullet_pool_manager.gd`
- **Línea:** 55 (inicio de `return_enemy_bullet`)
- **Cambio:** añadir `if bullet == null: return` como primera línea del cuerpo

### T5 — Eliminar `scenes/main/spawner.gd`
- **Archivo:** `scenes/main/spawner.gd`
- **Condición:** verificado huérfano (T1 pre-verificación confirma que no aparece en ninguna .tscn)
- **Acción:** eliminar del filesystem (git lo conserva si se necesita recuperar)

---

## Archivos a tocar (lista exhaustiva)

| Archivo | Acción | Tamaño del cambio |
|---------|--------|------------------|
| `r-type-2/.gdignore` | Crear (vacío) | Mínimo |
| `valkyrie-vii-(4.4)/.gdignore` | Crear (vacío) | Mínimo |
| `autoloads/bullet_pool_manager.gd` | Editar — 2 líneas añadidas | Mínimo |
| `scenes/main/spawner.gd` | Eliminar | — |

**Total archivos fuera de este set: 0.**

---

## Lo que NO hace el Worker

- No crea EventBus
- No implementa RunManager
- No toca HUD, enemigos, score, ni ningún sistema de M6+
- No limpia warnings ajenos al Bloque A
- No modifica project.godot
- No modifica ninguna .tscn

---

## Criterios de aceptación (para el Validator)

| # | Criterio |
|---|---------|
| CA-1 | `r-type-2/.gdignore` existe y está vacío |
| CA-2 | `valkyrie-vii-(4.4)/.gdignore` existe y está vacío |
| CA-3 | `return_bullet` tiene `if bullet == null: return` como primera línea |
| CA-4 | `return_enemy_bullet` tiene `if bullet == null: return` como primera línea |
| CA-5 | `scenes/main/spawner.gd` no existe en el filesystem |
| CA-6 | Ningún archivo fuera del set fue modificado |
| CA-7 | EventBus no fue introducido |
| CA-8 | project.godot autoloads: solo BulletPoolManager |
