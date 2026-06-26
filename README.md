# hwave

a ps2-style static horror game built in godot 4.7.

no names. no explanations.

---

## structure

```
hwave/
├── assets/
│   ├── backgrounds/     # ai-generated pre-rendered room backgrounds
│   └── sprites/         # figure, door, key sprites
├── scenes/
│   ├── main.tscn        # root scene
│   ├── shader_manager.tscn
│   ├── room_corridor.tscn
│   ├── room_side.tscn
│   ├── room_staircase.tscn
│   └── room_ending.tscn
├── scripts/
│   ├── game_manager.gd  # autoload singleton, flags, state
│   ├── sound_manager.gd # procedural audio synthesis
│   ├── shader_manager.gd
│   ├── main.gd
│   └── room_*.gd        # per-room logic
└── shaders/
    ├── ps2_horror.gdshader     # scanlines, grain, chromatic aberration, VHS glitch
    ├── darkness_overlay.gdshader # breathing shadow vignette
    ├── static_noise.gdshader   # tv static transitions
    └── item_glow.gdshader      # interactive item highlight
```

## shaders

- **ps2_horror** — full post-process pass simulating ps2/vhs degradation: scanlines, film grain, chromatic aberration, flicker, tracking glitches
- **darkness_overlay** — organic breathing darkness using fbm noise
- **static_noise** — tv static effect for transitions
- **item_glow** — warm pulsing glow for interactive items

## sound

all sound is synthesized procedurally in gdscript — no audio files needed.
generates: ambient drone, heartbeat, creaks, static bursts, breath sounds, horror stingers.

## running

open in godot 4.7, run `scenes/main.tscn`.

---

*click to move. click to interact.*
