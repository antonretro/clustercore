// Step a batch of test cases each frame
if (!global.__test_done) {
    test_runner_step();
}

// ESC returns to menu
if (keyboard_check_pressed(vk_escape)) {
    test_log_close();
    room_goto(room_menu);
    exit;
}

// F5 re-runs all tests
if (keyboard_check_pressed(vk_f5)) {
    test_log_close();
    test_runner_init();
    test_runner_register_all();
}

// Left/Right adjust batch speed
if (keyboard_check_pressed(vk_left))  global.__test_batch_size = max(1, global.__test_batch_size - 5);
if (keyboard_check_pressed(vk_right)) global.__test_batch_size += 5;
