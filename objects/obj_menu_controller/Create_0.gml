display_set_gui_size(1920, 1080);

// Typography scale — H1 (titles) → H2 (headers) → H3 (labels) → H4 (body) → SMALL (hints)
global.TXT_H1    = 7.0;   // Screen/page title   e.g. "SETTINGS", "STORY CLEAR"
global.TXT_H2    = 5.0;   // Section header       e.g. "SELECT LEVEL", card labels
global.TXT_H3    = 3.5;   // Panel values/labels  e.g. score number, combo count
global.TXT_H4    = 2.5;   // Body / description   e.g. mission name, card subtitle
global.TXT_SMALL = 1.8;   // Hints / footnotes    e.g. "Arrow Keys to Move", copyright

menu_index    = 0;
in_settings   = false;
in_story_select = false;
in_bonus_select = false;
in_refabricator = false;
in_inventory    = false;
in_shop         = false;
in_how_to_play  = false;
in_achievements = false;
settings_index = 0;
settings_items = ["Ghost Piece", "Screen Shake"];
how_to_page = 0;
how_to_max_pages = 5;

// Title screen
in_title        = true;

// Restore menu state from previous session
if (variable_global_exists("last_menu_state") && global.last_menu_state != "") {
    in_title = false;
    if (global.last_menu_state == "STORY_SELECT") { in_story_select = true; menu_index = 0; }
    if (global.last_menu_state == "STORY_LEVEL_SELECT") { in_story_select = true; in_story_level_select = true; menu_index = 0; }
    if (global.last_menu_state == "BONUS_SELECT") { in_bonus_select = true; menu_index = 0; }
    if (global.last_menu_state == "PLANET_ENDLESS") { in_title = false; menu_index = 1; }
    if (global.last_menu_state == "CLASSIC_ENDLESS") { in_title = false; menu_index = 2; }
    
    // Clear the state so it doesn't persist forever across hard launches
    global.last_menu_state = "";
}
title_timer     = 0;
menu_enter_timer = 0; // 0→60: cards slide in on menu entry
is_loading      = false;
loading_timer   = 0;
in_level_transition = false;
level_transition_timer = 0;
transition_target_world = 0;
transition_target_level = 0;
zoom_lerp = 0; // 0 = galaxy view, 1 = planet focus
screen_fade     = 1;  // start at 1 so title/menu appear instantly; 0→1 on sub-screen entry
exit_pending    = ""; // name of the flag to clear on exit anim complete

// Save slot system
in_save_slots = false;
save_slot_index = 0;
save_slots = [
    { name: "PILOT_01", progress: 0, shards: 0, playtime: "00:00:00" },
    { name: "PILOT_02", progress: 0, shards: 0, playtime: "00:00:00" },
    { name: "PILOT_03", progress: 0, shards: 0, playtime: "00:00:00" }
];
global.current_save_slot = 1;

// Name entry
in_name_entry = false;
name_entry_index = 0;
name_entry_text = "";

if (!variable_global_exists("settings")) {
    global.settings = { ghostEnabled: true, shakeEnabled: true };
}
if (!variable_global_exists("gameMode")) global.gameMode = "PLANET";
if (!variable_global_exists("storyPlanet")) global.storyPlanet = 0;
if (!variable_global_exists("story_seen_scenes")) global.story_seen_scenes = {};
if (!variable_global_exists("floatingTexts")) global.floatingTexts = [];
if (!variable_global_exists("COLOR_DANGER")) global.COLOR_DANGER = make_color_rgb(255, 50, 50);

dialogue_init();
wallet_load();

// Safe defaults for unlock flags if wallet_load didn't set them
if (!variable_global_exists("endlessPlanetUnlocked"))  global.endlessPlanetUnlocked  = false;
if (!variable_global_exists("endlessClassicUnlocked")) global.endlessClassicUnlocked = false;
if (!variable_global_exists("isFirstTimeLaunch"))      global.isFirstTimeLaunch      = false;

// Build menu labels based on unlock state
var _planetLabel  = "PLANET ENDLESS"  + (global.endlessPlanetUnlocked  ? "" : "  [LOCKED]");
var _classicLabel = "CLASSIC ENDLESS" + (global.endlessClassicUnlocked ? "" : "  [LOCKED]");

menu_items = [
    "STORY MODE",
    _planetLabel,
    _classicLabel,
    "SAVE GAME",
    "SHARDS",
    "INVENTORY",
    "SHOP",
    "ENCYCLOPEDIA",
    "ACHIEVEMENTS",
    "SETTINGS"
];
menu_hint  = [
    "Clear a chain of corrupted planets, one objective at a time.",
    global.endlessPlanetUnlocked  ? "The Galaxy Experience: Rotating board, Core planet, and Mining gravity." : "Complete TIN MOON in Story Mode to unlock.",
    global.endlessClassicUnlocked ? "The Arcade Classic: Pure matching, No rotation, Clean grid."           : "Complete RUST GARDEN in Story Mode to unlock.",
    "Persist your current progress to the cluster mainframe.",
    "Access the Refabricator: Transform raw shards into precious gems.",
    "Manage your collected equipment and pilot upgrades.",
    "Spend gems on specialized core-mining tech.",
    "A pilot's notebook: Basic movement to advanced cluster strategies.",
    "Track your galactic milestones and parody rewards.",
    "Toggle gameplay options."
];

story_select_index = clamp(global.storyPlanet, 0, 4);
in_story_level_select = false;
story_level_index = 0;
story_world_level_counts = [10, 10, 10, 10, 10];
story_level_names = [
    ["Wake Signal", "First Anchor", "Tin Run", "Core Loop", "Quiet Storm", "Moon Lock", "Shard Sweep", "Tidal Shift", "Low Orbit", "Tin Purge"],
    ["Rust Bloom", "Broken Lane", "Iron Rain", "Garden Wall", "Dead Roots", "Red Signal", "Cage Break", "Spore Flood", "Thorn Path", "Rust Purge"],
    ["Ante Up", "Lucky Spiral", "House Edge", "Wild Orbit", "Payout Burn", "Comet Vault", "Debt Run", "High Roller", "Jackpot Spin", "Comet Purge"],
    ["Cold Entry", "Low Oxygen", "Last Lane", "Grave Spin", "Black Relay", "Orbit Break", "Void Pull", "Zero Drift", "Silent Core", "Orbit Purge"],
    ["Gate Hum", "Six Color Lock", "Solar Teeth", "Final Spiral", "Sun Debt", "Core Door", "Prism Fire", "Key Run", "Last Stand", "Solar Purge"]
];
story_worlds = [
    { name: "TIN MOON",     orbit: 0.22, ang: 220, size: 18, color_a: make_color_rgb(120, 205, 230), color_b: make_color_rgb(55, 85, 130),  tilt: 0.34, sprite: spr_mercury },
    { name: "RUST GARDEN",  orbit: 0.34, ang: 310, size: 22, color_a: make_color_rgb(230, 125, 70),  color_b: make_color_rgb(95, 45, 35),   tilt: 0.39, sprite: spr_mars    },
    { name: "CASINO COMET", orbit: 0.46, ang: 25,  size: 20, color_a: make_color_rgb(255, 220, 90),  color_b: make_color_rgb(75, 150, 125), tilt: 0.43, sprite: spr_venus   },
    { name: "DEAD ORBIT",   orbit: 0.58, ang: 105, size: 24, color_a: make_color_rgb(160, 170, 190), color_b: make_color_rgb(55, 55, 80),   tilt: 0.36, sprite: spr_saturn  },
    { name: "CLUSTER CORE", orbit: 0.70, ang: 165, size: 28, color_a: make_color_rgb(180, 105, 255), color_b: make_color_rgb(60, 30, 110),  tilt: 0.48, sprite: spr_jupiter }
];
story_solar_spin = 0;
bonus_select_index = 0;
bonus_planet_names = ["GLASS DWARF", "EMBER DWARF", "COBALT DWARF", "VIOLET DWARF"];
bonus_planet_goals = [9000, 14000, 19000, 26000];
bonus_planet_rewards = [18, 26, 34, 48];

gp_prev_menu_stick_y = 0;
gp_prev_menu_stick_x = 0;

// Achievement data
if (!variable_global_exists("achievements")) {
    global.achievements = [
        { name: "TOUCHDOWN",      desc: "Successfully clear your first planet mission.",       unlocked: true },
        { name: "CLUSTER LUCK",   desc: "Clear a single cluster of 12+ blocks.",              unlocked: false },
        { name: "CORE BLIMEY",    desc: "Achieve an S-Rank on any Story level.",              unlocked: false },
        { name: "ARROW TO KNEE",  desc: "Clear a row using a Piercing Arrow beam.",           unlocked: true },
        { name: "GRAVITY SUCKS",  desc: "Survive for 5 minutes in Planet Endless mode.",      unlocked: false },
        { name: "CAGE MATCH",     desc: "Shatter a Locked Cage using two matches.",           unlocked: false },
        { name: "METEOR SHOWER",  desc: "Survive 3 debris impacts in a single turn.",         unlocked: false },
        { name: "PRISM POWER",    desc: "Clear a color-shifting Prism block.",                unlocked: false },
        { name: "SPORE LOSER",    desc: "Lose a planet to Void Spore corruption.",            unlocked: false },
        { name: "ORBITAL DRIFT",  desc: "Shift gravity sides 10 times in one level.",         unlocked: false },
        { name: "CHAIN REACTION", desc: "Trigger a massive 5x Combo chain.",                  unlocked: false },
        { name: "PERFECT ORBIT",  desc: "Clear a mission without using the Hold slot.",       unlocked: false },
        { name: "MONEY BAGS",     desc: "Earn your first 1,000 Shards.",                     unlocked: false },
        { name: "DIAMOND HANDS",  desc: "Hold a high-value block for 20+ turns.",             unlocked: false },
        { name: "SPEED DEMON",    desc: "Clear a mission in under 60 seconds.",               unlocked: false },
        { name: "ZEN GARDEN",     desc: "Clear all Space Junk on a single planet.",           unlocked: false },
        { name: "CROSS PURPOSES", desc: "Clear a Cross-Arrow (ULDR) block.",                  unlocked: false },
        { name: "LOCKSMITH",      desc: "Open 10 cages in a single game session.",            unlocked: false },
        { name: "ANTIGRAVITY",    desc: "Rotate the board 360 before a piece lands.",         unlocked: false },
        { name: "THE 1%",         desc: "Reach a galactic score of 1,000,000.",               unlocked: false }
    ];
}

// First-time player: trigger backstory intro cinematic
if (global.isFirstTimeLaunch) {
    global.isFirstTimeLaunch = false;
    in_title = false; // skip title on very first launch to show backstory immediately
    dialogue_start_scene("backstory_intro");
}
