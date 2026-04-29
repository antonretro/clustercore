// In obj_game_manager (or wherever you're handling game over logic)

if (global.gameOverState) {
    draw_game_over_screen();
}

function draw_game_over_screen() {
    // Draw the background for the game over screen (optional)
    draw_set_color(c_black);  // Set color to black or any background color
    draw_rectangle(0, 0, display_get_width(), display_get_height(), false); // Optional, can use background image

    // Draw the game over text
    draw_set_color(c_white);
    draw_text(display_get_width() / 2 - 100, display_get_height() / 2 - 50, "GAME OVER!");
    draw_text(display_get_width() / 2 - 100, display_get_height() / 2 + 10, "Press R to Restart");
}
