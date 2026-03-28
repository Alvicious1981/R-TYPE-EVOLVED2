# M14 — Parallax Scrolling Background Design

**Date:** 2026-03-28
**Status:** Approved
**Milestone:** M14

---

## Goal

Replace the single-layer procedural starfield (`background.gd` / `Node2D`) in `Main.tscn` with a three-layer `ParallaxBackground` system that gives the illusion of infinite, framerate-independent rightward space-flight at warp speed.

---

## Architecture

### Option chosen: B — Dedicated `Background.tscn` instanced into Main

`scenes/levels/Background.tscn` is self-contained, independently previewable, and portable to future levels. The canonical CLAUDE.md folder for backgrounds is `scenes/levels/`.

### Node topology

```
Background.tscn
└── ParallaxBackground  "Background"  [root]  z_index = -10
    │   script: scenes/levels/parallax_scroller.gd
    │
    ├── ColorRect  "BaseColor"           (fixed — NOT a ParallaxLayer)
    │   size = 1920 × 1080, color = #050514 (0.02, 0.02, 0.08, 1.0)
    │
    ├── StarsDistant  [ParallaxLayer]
    │   motion_scale    = Vector2(0.05, 0.0)
    │   motion_mirroring = Vector2(1920, 0)
    │   └── Sprite2D  "StarSprite"  centered=false  texture_filter=NEAREST
    │       Texture: code-generated ImageTexture (_ready)
    │       200 × 1×1 px white pixels, alpha 0.5–0.7, cool blue tint
    │
    ├── Nebula  [ParallaxLayer]
    │   motion_scale    = Vector2(0.25, 0.0)
    │   motion_mirroring = Vector2(1920, 0)
    │   └── Sprite2D  "NebulaSprite"  centered=false  texture_filter=NEAREST
    │       Texture: NoiseTexture2D (FastNoiseLite Perlin FBM, 1920×1080)
    │       modulate = Color(0.4, 0.15, 0.7, 0.45)  — deep purple/cyan tint
    │
    └── StarsNear  [ParallaxLayer]
        motion_scale    = Vector2(0.75, 0.0)
        motion_mirroring = Vector2(1920, 0)
        └── Sprite2D  "NearSprite"  centered=false  texture_filter=NEAREST
            Texture: code-generated ImageTexture (_ready)
            80 × 2×2 px pixels, alpha 0.85–1.0, 15% chance yellow-white tint

Main.tscn: old `[node name="Background" type="Node2D"]` → instance of Background.tscn
```

---

## Scroll Logic (`parallax_scroller.gd`)

```
extends ParallaxBackground

SCROLL_SPEED: float = 200.0

_ready():
    generate ImageTexture for StarsDistant/StarSprite
    generate ImageTexture for StarsNear/NearSprite

_process(delta):
    scroll_offset.x -= SCROLL_SPEED * delta   # framerate-independent
```

`scroll_offset` on `ParallaxBackground` is multiplied by each layer's `motion_scale` to produce per-layer offsets. `motion_mirroring = Vector2(1920, 0)` tiles the sprite horizontally every 1920 px, producing a seamless infinite loop.

---

## Texture Strategy (hybrid)

| Layer | Method | Rationale |
|---|---|---|
| StarsDistant | Code-gen `ImageTexture` (1×1 px dots) | Precise arcade pixel look, deterministic seed |
| Nebula | `NoiseTexture2D` + FastNoiseLite Perlin FBM | Engine-native, no external assets, atmospheric |
| StarsNear | Code-gen `ImageTexture` (2×2 px dots) | Fatter pixels = closer = depth illusion |

---

## Z-Index & UI Safety

- `Background` root: `z_index = -10` → behind all gameplay nodes
- `HUD.tscn` is a `CanvasLayer` → renders in its own stack, completely isolated from 2D z_index; parallax cannot bleed into HUD regardless of depth

---

## Files Created / Modified

| Action | Path |
|---|---|
| CREATE | `scenes/levels/Background.tscn` |
| CREATE | `scenes/levels/parallax_scroller.gd` |
| MODIFY | `scenes/main/Main.tscn` — swap Background node |
| RETIRE (unreferenced) | `scenes/main/background.gd` |
