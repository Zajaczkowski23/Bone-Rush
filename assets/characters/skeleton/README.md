# Sword skeleton

Original skeleton enemy generated with the built-in ImageGen tool, then downscaled and split using LibreSprite 1.3. The editable `Skeleton.aseprite` is a 384 x 256 atlas with four rows, not a timeline animation.

- Row 1: idle, 6 frames, 6 FPS.
- Row 2: run, 6 frames, 10 FPS.
- Row 3: attack, 6 frames, 10 FPS. Damage occurs at frame 3 (zero-based).
- Row 4: death, 6 frames, 10 FPS.

Each exported PNG is 384 x 64 with six 64 x 64 frames, transparent background and nearest-neighbor pixels. Godot uses `characters/enemies/enemy/skeleton_frames.tres` and `enemy.tscn`. All spawned enemies are chasing skeletons.

Prompt: original sword skeleton compatible with Tiny Swords fantasy pixel art; chunky ivory skull, dark navy outline, bone ribs and limbs, muted burgundy waist cloth, leather boots and rusty steel sword; four rows of six consistent idle, walking, sword attack and collapsing-bones death frames, transparent background, no labels.
