# godotSpriteSheetFrameCounter
Godot code that tries to estimate how many frames there are in a sprite sheet

Drag your sheet to the sprite's texture, run it, and it will print the x,y frame arrangement.

Did this because I was annoyed having to manually pick frames every time I added an animated sprite, and figured it could be done programmatically.  This isn't 100% perfect, especially on tiles with almost no transparency (like tiles_packed.png), but it'll give a reasonable best guess, which will at the bare minimum be better than assuming everything is 4x4.

Spritesheets in the Kenney_Sprites folder are from Kenney, released under CC0
 https://kenney.nl/assets 
Ars_Notoria sprites by Balmer, released under CC0 
 https://opengameart.org/content/hero-spritesheets-ars-notoria 
Superpowers sprites by Pixel-Boy, released under CC0
 https://github.com/sparklinlabs/superpowers-asset-packs 
