// Game Settings
global.GRID_SIZE = 10;   // Width of the grid
global.GRID_HEIGHT = 20;  // Height of the grid
global.board = array_create(global.GRID_HEIGHT, array_create(global.GRID_SIZE));

// Initialize all positions in the board as null (empty)
for (var _y = 0; _y < global.GRID_HEIGHT; _y++) {
    for (var _x = 0; _x < global.GRID_SIZE; _x++) {
        global.board[_y][_x] = undefined;  // Empty spot
    }
}

// Current block state
currentBlock = {
    x: 4,  // Starting X position
    y: 0   // Starting Y position
};

// Move block left
if (keyboard_check(vk_left)) {
    if (can_move(currentBlock.x - 1, currentBlock.y)) {
        currentBlock.x -= 1;
    }
}

// Move block right
if (keyboard_check(vk_right)) {
    if (can_move(currentBlock.x + 1, currentBlock.y)) {
        currentBlock.x += 1;
    }
}

// Move block down
if (keyboard_check(vk_down)) {
    if (can_move(currentBlock.x, currentBlock.y + 1)) {
        currentBlock.y += 1;
    }
}

// Function to check if the block can move
function can_move(_x, _y) {
    if (_x >= 0 && _x < global.GRID_SIZE && _y < global.GRID_HEIGHT) {
        return global.board[_y][_x] == undefined; // Make sure there's no block already in that position
    }
    return false;
}
