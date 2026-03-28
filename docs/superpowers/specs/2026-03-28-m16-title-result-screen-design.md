# M16 Design — TitleScreen + ResultScreen

**Date:** 2026-03-28
**Status:** Approved — executing

---

## Problem

The game loop has no formal entry point or exit point:
- ShipSelect is the main scene (lacks branding / "first impression")
- On victory (`run_complete`), HUD shows a static label — no scene transition
- On defeat (player death), only a flash overlay — no transition

## Target Loop

```
TitleScreen → ShipSelect → Main (Gameplay) → ResultScreen → (Retry → Main | Menu → TitleScreen)
```

---

## TitleScreen

**Scene:** `scenes/ui/TitleScreen.tscn`
**Script:** `scenes/ui/title_screen.gd`

### Nodes
- `Node2D` (root, script attached)
  - `ColorRect` "Background" — full 1920×1080, dark navy `Color(0.03, 0.03, 0.06)`
  - `Label` "TitleLabel" — "VALKYRIE", font_size 120, centered, y=280
  - `Label` "RomanLabel" — "VII", font_size 56, cyan `Color(0.3, 0.7, 1.0)`, y=440
  - `Label` "PressStartLabel" — "PRESS  SPACE  TO  START", font_size 36, y=720

### Behavior
- `_ready()`: starts Tween blink loop on PressStartLabel (alpha 1.0→0.0→1.0, 0.5s each)
- `_input()`: `ui_accept` → `change_scene_to_file("res://scenes/ui/ShipSelect.tscn")`

---

## ResultScreen

**Scene:** `scenes/ui/ResultScreen.tscn`
**Script:** `scenes/ui/result_screen.gd`

### Nodes
- `Node2D` (root, script attached)
  - `ColorRect` "Background" — full 1920×1080, near-black `Color(0.02, 0.02, 0.04)`
  - `Label` "OutcomeLabel" — "MISSION COMPLETE" or "MISSION FAILED", font_size 60, y=100
  - `Label` "ScoreLabel" — "SCORE  XXXXX", font_size 42, y=400
  - `Label` "RankLabel" — S/A/B/C letter, font_size 200, y=460
  - `Label` "HintLabel" — "[ R ] RETRY    [ ESC ] MAIN MENU", font_size 28, grey, y=880

### Rank Thresholds
| Score | Rank | Color |
|-------|------|-------|
| ≥ 5000 | S | Gold `(1.0, 0.9, 0.2)` |
| ≥ 3000 | A | Cyan `(0.4, 0.8, 1.0)` |
| ≥ 1000 | B | Green `(0.5, 1.0, 0.5)` |
| < 1000 | C | Grey `(0.8, 0.8, 0.8)` |

### Data Source
- `GameState.final_score: int` — set by EncounterDirector before scene change
- `GameState.run_victory: bool` — set by EncounterDirector before scene change

### Input
- `ui_restart` (R) → reset GameState, `change_scene_to_file("res://scenes/main/Main.tscn")`
- `ui_cancel` (Escape) → reset GameState, `change_scene_to_file("res://scenes/ui/TitleScreen.tscn")`

---

## EncounterDirector Changes

Adds `_finish_run(victory: bool)` to centralize both exit paths:
- Victory: emit `run_complete` (HUD label), 2.0s delay, → ResultScreen
- Defeat: 2.5s delay (death overlay visible), → ResultScreen
- Saves `RunManager.current_score` to `GameState.final_score` before transition

## Player Changes

Remove R-key reload from `State.DEAD` branch — ResultScreen owns retry.

## project.godot Change

`config/run/main_scene` → `"res://scenes/ui/TitleScreen.tscn"`
