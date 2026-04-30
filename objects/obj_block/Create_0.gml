// Initialize properties (set by manager)
type = "normal";
color = c_white;
dir = 0;
color_id = 0;
core_arrow = false;
grid_x = 0;
grid_y = 0;

// Visual interpolation
render_x = x;
render_y = y;
scale_x = 1.0;
scale_y = 1.0;
rotation = 0;
visualRotation = 0;
clearing = false;
clear_timer = 0;
clear_timer_max = 20;

shield_hp = 2;

// Sprite assignment (to be handled in Draw or here)
function update_sprite() {
    // 1. Assign Base Color Sprite
    switch(color_id) {
        case 1: sprite_index = spr_pinkSprite; break;
        case 2: sprite_index = spr_orangeSprite; break; 
        case 3: sprite_index = spr_yellowSprite; break; 
        case 4: sprite_index = spr_redSprite; break;
        case 5: sprite_index = spr_lightblueSprite; break;
        case 6: sprite_index = spr_greenSprite; break;
        default: sprite_index = spr_pinkSprite; break;
    }
    
    // 2. Overwrite for special solo types
    if (type == "bomb") sprite_index = spr_bomb;
    if (type == "dead") sprite_index = spr_deadmetal;
    if (type == "drill") sprite_index = spr_drill;
    // Core blocks now look like normal colored blocks to keep them matchable
    if (type == "asteroid") {
        if (asset_get_index("spr_asteroid") != -1) {
            sprite_index = spr_space_rock;
            image_index = (shield_hp <= 1 ? 1 : 0);
        }
    }
    // Metal blocks KEEP their color sprite, but will have an arrow drawn on top.
}

// Initial update
update_sprite();
