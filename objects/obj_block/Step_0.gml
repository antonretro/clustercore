// Smooth movement interpolation
x = lerp(x, (grid_x - global.HIDDEN_SIDES) * 16, 0.25);
y = lerp(y, (grid_y - global.HIDDEN_ROWS) * 16, 0.25);

// Recovery from squash/stretch
scale_x = lerp(scale_x, 1.0, 0.15);
scale_y = lerp(scale_y, 1.0, 0.15);

// --- Clear Animation ---
if (clearing) {
    clear_timer++;
    var _pct = clear_timer / clear_timer_max;
    
    // Zoom Out / Shrink and Rotate
    scale_x = 1.0 - _pct;
    scale_y = 1.0 - _pct;
    rotation += 25; // Fast spin
    
    // Fade out (using image_alpha)
    image_alpha = 1.0 - _pct;
    
    // Tiny bits of vibration
    x += random_range(-1, 1);
    y += random_range(-1, 1);
    
    if (clear_timer >= clear_timer_max) {
        instance_destroy();
    }
}
