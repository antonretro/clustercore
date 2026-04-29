// Set grid size and block size
game_grid_width = 6;
game_grid_height = 6;
block_size = 64;

// Create the grid data structure
game_grid = ds_grid_create(game_grid_width, game_grid_height);

// Define the colors (obj names for color blocks)
color_types = ["obj_darkblue", "obj_green", "obj_lightblue", "obj_pink", "obj_red", "obj_yellow"];

// Loop to initialize the grid with color blocks
for (var _x = 0; _x < game_grid_width; _x++) {
    for (var _y = 0; _y < game_grid_height; _y++) {
        // Randomly choose a block type
        var block_type = choose(color_types);

        // Place the block in the grid at the correct position
        game_grid[# _x, _y] = instance_create_layer(_x * block_size, _y * block_size, "GameLayer", block_type);
    }
}

// Additional setup for game variables (score, moves, etc.)
score = 0;
moves = 5;
game_over = false;
