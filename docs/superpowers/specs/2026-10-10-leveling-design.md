# Run leveling

The user approved XP on kills, thresholds of 50/80/110 XP, a paused choice
of one of three upgrades, and an XP bar and level indicator. Progress resets
with each new game scene. Score and XP are independent.

## Behavior

- Skeletons grant 10 XP exactly once on death, independently of score.
- Start at level 1 with 0 XP. The next level costs `50 + 30 * (level - 1)`.
  Preserve excess XP and queue one reward for every level crossed.
- Defer opening the reward panel until the current combat callback finishes,
  so an area attack can finish awarding all kills.
- Pause the scene tree while choosing. Only the panel processes input during
  this pause. Offer three distinct upgrades chosen from four repeatable ones:
  +5 sword damage; +20 maximum and current HP; +15 attack range;
  +10% current movement speed. HP cannot exceed its new maximum.
- Consume one reward per selection; keep paused until the reward queue is
  empty. Invalid or duplicate selections do not consume a reward.
- Ignore XP/rewards after death. Freeing/reloading a game during its reward
  pause restores the tree's unpaused state.
- Keep UI text in English to match the existing HUD, support mouse, touch,
  and keyboard selection, and show the new health maximum immediately.

## Components

`game/level_progression.gd` owns XP arithmetic and signals.
`game/upgrades/upgrade_definition.gd` and four `.tres` resources define upgrades.
`game/level_up_panel.gd/.tscn` own the paused reward UI and selection guard.
`game/game.gd` connects deaths, progression, HUD, and the pending reward queue.
`characters/player/player.gd` applies stat changes and updates health UI.

## Verification

Headless tests cover exact thresholds, carryover, multiple rewards, independent
score/XP, single death award, all upgrade effects, pause/input/queue behavior,
dead-player guards, and reset/cleanup. Run all existing combat/navigation tests.
Render the live HUD and reward panel for visual inspection.
