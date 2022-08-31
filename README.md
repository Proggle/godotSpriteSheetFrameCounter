# godotSpriteSheetFrameCounter
Godot code that tries to estimate how many frames there are in a sprite sheet

Drag your sheet to the sprite's texture, run it, and it will print the x,y frame arrangement.

Did this because I was annoyed having to manually pick frames every time I added an animated sprite, and figured it could be done programmatically.  This isn't 100% perfect, especially on tiles with almost no transparency (like tiles_packed.png), but it'll give a reasonable best guess, which will at the bare minimum be better than assuming everything is 4x8.

Demo spritesheets are CC0 from Kenney ( https://kenney.nl/assets)
