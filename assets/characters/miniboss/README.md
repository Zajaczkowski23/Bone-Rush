# Bone King miniboss

Original artwork created with built-in ImageGen and exported into four animation sheets with LibreSprite 1.3. The four row PNGs are the initial LibreSprite exports. Idle, run and death use variable atlas regions directly from Miniboss_Source.png because swords, crowns and the swing extend beyond the nominal 256 x 256 grid. Each region is padded into a 416 x 416 virtual frame using AtlasTexture.margin; the original 256 x 256 cell stays centered, preserving the sprite size and ground position. Godot renders at 0.5 scale with linear filtering.

Animations: idle (6 FPS), run (8 FPS), attack (6 FPS), death (8 FPS). Attack damage lands on frame 3 (zero-based), after 0.5 seconds of windup. The ground ring previews attack range during that windup.

Gameplay: 240 HP, 25 damage, 68 px range, 75 px/s movement, 1.8 s attack interval, 100 score and 80 XP. A timer attempts a spawn every 30 seconds and allows at most one living Bone King. The base skeleton navigation and wall checks are inherited; the ground footprint is unchanged to fit the existing ramps.

Prompt: original royal skeleton miniboss in a Tiny Swords-compatible refined fantasy sprite style, cracked skull, broken gold crown, dark slate shoulder armor, burgundy cape, heavy chipped greatsword, amber eye; six columns and four rows of idle, marching, heavy sword swing and collapsing death animations; transparent 1536 x 1024 sheet with consistent character design.

Attack uses six separate Miniboss_Attack_0.png through Miniboss_Attack_5.png images exported and cleaned in LibreSprite. The original atlas has adjacent sword/arc pixels inside the rectangular bounds of the recovery poses; these disconnected fragments were erased while preserving the main pose and its antialiasing. Atlas margins preserve the same ground alignment.
