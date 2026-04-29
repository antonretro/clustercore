/** * CLUSTERCORE - CORE ENGINE
 * Created by Anton Retro
 */

/* --- Configuration --- */
const CONFIG = {
    cols: 5,
    rows: 9,
    hiddenRows: 2,
    dropIntervalStart: 1000, // Slower start
    colors: {
        1: '#FF6B6B', // Pink
        2: '#FF922B', // Orange
        3: '#FCC419', // Yellow
        4: '#B197FC', // Purple
        5: '#66D9E8', // Cyan
        6: '#4DABF7', // Blue
        bomb: '#212529', // Dark Grey
        dead: '#4a4e53',  // Dead Metal Grey
        laser: '#FFFFFF' // Laser White
    }
};
const TOTAL_ROWS = CONFIG.rows + CONFIG.hiddenRows;

/* --- Text System (Paintra-style named copy) --- */
const TEXT = {
    menuEndlessTitle: 'Endless',
    menuEndlessDesc: 'Survive, cash out shards, and build the Core.',
    menuChallengeTitle: 'Challenge',
    menuChallengeDesc: 'Clear focused missions for bigger shard payouts.',
    menuTimeTitle: 'Time Attack',
    menuTimeDesc: 'Race the clock. Combos add time and shards.',
    shopTitle: 'Core Lab',
    shopDesc: 'Permanent upgrades bought with Core Shards.',
    shards: 'Core Shards',
    best: 'Best',
    drillBore: 'Deep Bore',
    drillBoreDesc: 'Drills clear more of the column and pay more shards.',
    capacitor: 'Capacitor',
    capacitorDesc: 'Special pieces appear more often.',
    magnet: 'Magnetism',
    magnetDesc: 'Every clear scores more points.',
    maxed: 'MAX',
    buy: 'BUY',
    notEnough: 'Need more shards',
    purchased: 'Upgrade online',
    drill: 'DRILL',
    combo: 'COMBO',
    shardBurst: 'SHARDS',
    jackpot: 'Jackpot',
    fever: 'FEVER',
    feverReady: 'FEVER READY',
    levelUp: 'LEVEL UP',
    coreFailure: 'CORE FAILURE',
    gamePaused: 'Game Paused',
    finalScore: 'Final Score'
};

function t(key) {
    return TEXT[key] || key;
}

const META_UPGRADES = {
    drillBore: {
        nameKey: 'drillBore',
        descKey: 'drillBoreDesc',
        max: 4,
        baseCost: 18,
        costStep: 18
    },
    capacitor: {
        nameKey: 'capacitor',
        descKey: 'capacitorDesc',
        max: 5,
        baseCost: 24,
        costStep: 22
    },
    magnet: {
        nameKey: 'magnet',
        descKey: 'magnetDesc',
        max: 5,
        baseCost: 20,
        costStep: 20
    }
};

function defaultMeta() {
    return {
        cores: 0,
        bestScore: 0,
        totalCores: 0,
        upgrades: {
            drillBore: 0,
            capacitor: 0,
            magnet: 0
        }
    };
}

function loadMeta() {
    try {
        const loaded = JSON.parse(localStorage.getItem('clusterCoreMeta') || 'null');
        return {
            ...defaultMeta(),
            ...(loaded || {}),
            upgrades: {
                ...defaultMeta().upgrades,
                ...((loaded && loaded.upgrades) || {})
            }
        };
    } catch (e) {
        console.warn('ClusterCore meta save was unreadable, starting fresh.', e);
        return defaultMeta();
    }
}

function saveMeta() {
    localStorage.setItem('clusterCoreMeta', JSON.stringify(state.meta));
}

function getUpgradeLevel(id) {
    return state.meta.upgrades[id] || 0;
}

function getUpgradeCost(id) {
    const up = META_UPGRADES[id];
    return up.baseCost + (getUpgradeLevel(id) * up.costStep);
}

/* --- Missions Data --- */
const MISSIONS = [
    { id: 1, name: "First Steps", desc: "Clear 30 blocks.", type: "blocks", target: 30, diff: 1 },
    { id: 2, name: "Diagonal Beginner", desc: "Clear 1 diagonal line (4+ blocks).", type: "diagonal", target: 1, diff: 1 },
    { id: 3, name: "Level Up", desc: "Reach Level 3.", type: "level", target: 3, diff: 1 },
    { id: 4, name: "Drill Team", desc: "Use 3 Drill objects.", type: "drill", target: 3, diff: 2 },
    { id: 5, name: "Red Alert", desc: "Clear 2 Red clusters.", type: "color", colorId: 1, target: 2, diff: 2 },
    { id: 6, name: "Arrow Storm", desc: "Clear 3 Arrow clusters.", type: "arrow", target: 3, diff: 2 },
    { id: 7, name: "Combo Rookie", desc: "Achieve a 2x Combo.", type: "combo", target: 2, diff: 3 },
    { id: 8, name: "Speed Run", desc: "Clear 30 blocks in 2 minutes.", type: "timed_blocks", target: 30, timeLimit: 120, diff: 3 },
    { id: 9, name: "Demolition", desc: "Use 5 Bombs.", type: "bomb", target: 5, diff: 3 },
    { id: 10, name: "Survivor", desc: "Survive for 2 minutes.", type: "survival", timeLimit: 120, diff: 3 },
    { id: 11, name: "Master Diagonal", desc: "Clear 3 diagonal lines.", type: "diagonal", target: 3, diff: 4 },
    { id: 12, name: "High Climber", desc: "Reach Level 10.", type: "level", target: 10, diff: 5 }
];

/* --- State Management --- */
let state = {
    grid: [],
    score: 0,
    level: 1,
    levelScore: 0,
    scoreToNext: 1500,
    gameOver: false,
    paused: true,
    activePiece: null,
    nextPiece: null,
    holdPiece: null,
    canHold: true,
    activeColors: [],
    reserveColors: [],
    lastTime: 0,
    dropTimer: 0,
    particles: [],
    trails: [],
    floatingTexts: [],
    runCores: 0,
    comboBest: 0,
    lastClearSize: 0,
    jackpotMeter: 0,
    feverTimer: 0,
    payoutFlash: 0,
    meta: loadMeta(),
    settingsOpen: false,
    settings: {
        ghostEnabled: true,
        shakeEnabled: true,
        beamEnabled: true,
        mouseEnabled: localStorage.getItem('mouseEnabled') === 'true',
        controlScheme: localStorage.getItem('controlScheme') || 'swipe' // Load from storage or default to swipe
    },
    spaceLocked: false,

    // Swipe State
    touchStartX: 0,
    touchStartY: 0,
    touchLastX: 0,
    touchLastY: 0,
    isDragging: false,
    dragThreshold: 10, // Pixels to consider a drag
    tapThreshold: 200, // ms to consider a tap
    touchStartTime: 0,

    // New Mode State
    gameMode: 'menu',
    currentMission: null,
    missionProgress: 0,
    missionComplete: false,
    timeAttackTimer: 60,
    timeAttackStartTime: 0,
    missionStartTime: 0,
    lastMouseColumn: null, // Track cursor position for spawn
    pausedBeforeSettings: false // Track if settings were opened from pause menu
};

/* --- Audio System --- */
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
const soundManager = {
    masterGain: audioCtx.createGain(),
    sfxGain: audioCtx.createGain(),
    musicGain: audioCtx.createGain(),

    init() {
        this.masterGain.connect(audioCtx.destination);
        this.sfxGain.connect(this.masterGain);
        this.musicGain.connect(this.masterGain);

        this.updateVolumes();
    },

    updateVolumes() {
        const mEl = document.getElementById('settings-vol-master') || document.getElementById('vol-master');
        const sEl = document.getElementById('settings-vol-sfx') || document.getElementById('vol-sfx');
        const muEl = document.getElementById('settings-vol-music') || document.getElementById('vol-music');

        const m = mEl ? Number(mEl.value) / 100 : 0.5;
        const s = sEl ? Number(sEl.value) / 100 : 0.8;
        const mu = muEl ? Number(muEl.value) / 100 : 0.3;

        this.masterGain.gain.value = m;
        this.sfxGain.gain.value = s;
        this.musicGain.gain.value = mu;

        if (typeof musicManager !== 'undefined' && typeof musicManager.setVolume === 'function') {
            musicManager.setVolume(m * mu);
        }
    },

    play(type, param) {
        if (audioCtx.state === 'suspended') audioCtx.resume();

        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(this.sfxGain);

        const now = audioCtx.currentTime;

        switch (type) {
            case 'move':
                osc.type = 'square';
                osc.frequency.setValueAtTime(200, now);
                osc.frequency.exponentialRampToValueAtTime(100, now + 0.05);
                gain.gain.setValueAtTime(0.1, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.05);
                osc.start(now);
                osc.stop(now + 0.05);
                break;
            case 'drop':
                osc.type = 'triangle';
                osc.frequency.setValueAtTime(150, now);
                osc.frequency.exponentialRampToValueAtTime(50, now + 0.1);
                gain.gain.setValueAtTime(0.2, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.1);
                osc.start(now);
                osc.stop(now + 0.1);
                break;
            case 'match':
                // Pentatonic scale based on chain
                const baseFreqs = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]; // C4, D4, E4, G4, A4, C5
                const note = baseFreqs[Math.min(param || 0, baseFreqs.length - 1)];
                osc.type = 'sine';
                osc.frequency.setValueAtTime(note, now);
                gain.gain.setValueAtTime(0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);
                osc.start(now);
                osc.stop(now + 0.3);
                break;
            case 'explode':
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(100, now);
                osc.frequency.exponentialRampToValueAtTime(10, now + 0.3);
                gain.gain.setValueAtTime(0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.3);
                osc.start(now);
                osc.stop(now + 0.3);
                break;
            case 'gameover':
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(400, now);
                osc.frequency.linearRampToValueAtTime(50, now + 1.0);
                gain.gain.setValueAtTime(0.3, now);
                gain.gain.linearRampToValueAtTime(0.01, now + 1.0);
                osc.start(now);
                osc.stop(now + 1.0);
                break;
            case 'laser':
                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(800, now);
                osc.frequency.exponentialRampToValueAtTime(100, now + 0.4);
                gain.gain.setValueAtTime(0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.4);
                osc.start(now);
                osc.stop(now + 0.4);
                break;
            case 'menu_click':
                osc.type = 'sine';
                osc.frequency.setValueAtTime(600, now);
                osc.frequency.exponentialRampToValueAtTime(300, now + 0.1);
                gain.gain.setValueAtTime(0.1, now);
                gain.gain.exponentialRampToValueAtTime(0.01, now + 0.1);
                osc.start(now);
                osc.stop(now + 0.1);
                break;
            case 'success':
                osc.type = 'triangle';
                osc.frequency.setValueAtTime(440, now);
                osc.frequency.setValueAtTime(554, now + 0.1);
                osc.frequency.setValueAtTime(659, now + 0.2);
                gain.gain.setValueAtTime(0.2, now);
                gain.gain.linearRampToValueAtTime(0, now + 0.6);
                osc.start(now);
                osc.stop(now + 0.6);
                break;
        }
    }
};

/* --- Haptic Feedback Manager --- */
const hapticManager = {
    vibrate(pattern) {
        // Check if vibration API is available
        if (!navigator.vibrate) return;

        // Pattern can be a single number or array [vibrate, pause, vibrate, ...]
        try {
            navigator.vibrate(pattern);
        } catch (e) {
            console.warn('Vibration failed:', e);
        }
    },

    // Light tap for button presses and piece movement
    light() {
        this.vibrate(10);
    },

    // Medium feedback for piece placement
    medium() {
        this.vibrate(20);
    },

    // Strong feedback for hard drop
    strong() {
        this.vibrate(30);
    },

    // Explosion pattern for bombs
    explosion() {
        this.vibrate([0, 20, 10, 30]);
    },

    // Drill pattern - continuous rumble
    drill() {
        this.vibrate([0, 15, 10, 15, 10, 20]);
    },

    // Success pattern for clearing blocks
    success() {
        this.vibrate([0, 10, 5, 15]);
    },

    // Pattern for matching/clearing
    clear() {
        this.vibrate(25);
    }
};

const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const previewCanvas = document.getElementById('preview-canvas');
const pCtx = previewCanvas.getContext('2d');
const holdCanvas = document.getElementById('hold-canvas');
const hCtx = holdCanvas.getContext('2d');

let cellSize = 60;

/* --- Initialization --- */
function init() {
    try {
        // YouTube Playables SDK Integration
        const inPlayablesEnv = typeof ytgame !== "undefined" && ytgame.IN_PLAYABLES_ENV;

        if (inPlayablesEnv) {
            // Set up pause/resume handlers
            ytgame.system.onPause(() => {
                if (!state.gameOver && state.activePiece) {
                    state.paused = true;
                }
            });

            ytgame.system.onResume(() => {
                if (!state.gameOver && state.activePiece) {
                    state.paused = false;
                }
            });

            // Set up audio enabled change handler
            ytgame.system.onAudioEnabledChange((isAudioEnabled) => {
                if (isAudioEnabled) {
                    audioCtx.resume();
                } else {
                    audioCtx.suspend();
                }

                if (typeof musicManager !== 'undefined' && typeof musicManager.setEnabled === 'function') {
                    musicManager.setEnabled(isAudioEnabled);
                }
            });

            // Initialize audio state
            const isAudioEnabled = ytgame.system.isAudioEnabled();
            if (!isAudioEnabled) {
                audioCtx.suspend();
            }

            if (typeof musicManager !== 'undefined' && typeof musicManager.setEnabled === 'function') {
                musicManager.setEnabled(isAudioEnabled);
            }
        }

        // Initialize Grid
        state.grid = Array(TOTAL_ROWS).fill().map(() => Array(CONFIG.cols).fill(null));

        // Setup System
        try { resize(); window.addEventListener('resize', resize); } catch (e) { console.warn("Resize init failed", e); }
        try { soundManager.init(); } catch (e) { console.warn("Sound init failed", e); }
        try { setupControls(); } catch (e) { console.warn("Controls init failed", e); }
        try { setupSettings(); } catch (e) { console.warn("Settings init failed", e); }
        try { updateControlsText(); } catch (e) { console.warn("Controls text init failed", e); }
        try { applyTextSystem(); renderMetaUI(); } catch (e) { console.warn("Text/meta UI init failed", e); }

        // Initialize Menu
        showMainMenu();

        // Show Banner Ad
        if (typeof adManager !== 'undefined') {
            adManager.showBanner();
        }

        // Signal first frame ready to YouTube
        if (inPlayablesEnv) {
            ytgame.game.firstFrameReady();
        }

        // Render Missions with explicit check
        try {
            renderMissions();
        } catch (e) {
            console.error("Mission render failed:", e);
            const grid = document.getElementById('mission-grid');
            if (grid) grid.innerHTML = '<div style="color:red; padding:20px;">Error loading missions.</div>';
        }

        // Signal game ready to YouTube after a short delay for rendering
        setTimeout(() => {
            if (inPlayablesEnv) {
                ytgame.game.gameReady();
            }
        }, 100);

        requestAnimationFrame(gameLoop);
    } catch (e) {
        console.error("Game Initialization Failed:", e);
        alert("Game failed to load: " + e.message);

        // Log error to YouTube if available
        if (typeof ytgame !== "undefined" && ytgame.IN_PLAYABLES_ENV) {
            ytgame.health.logError();
        }
    }
}

/* --- Menu & Navigation --- */
function showMainMenu() {
    hideAllScreens();
    document.getElementById('screen-main-menu').classList.remove('hidden');
    document.getElementById('bottom-nav').style.display = 'flex';
    updateActiveNav('Home');
    state.gameMode = 'menu';
    state.paused = true;
    renderMetaUI();

    // Play menu music (intro -> loop)
    if (typeof musicManager !== 'undefined') {
        musicManager.play('menu');
    }
}

function showChallengeSelect() {
    hideAllScreens();
    try {
        renderMissions(); // Force render to ensure they appear
    } catch (e) {
        console.error("Error rendering missions:", e);
        const grid = document.getElementById('mission-grid');
        if (grid) grid.innerHTML = '<div style="color:red;">Error loading missions.</div>';
    }
    document.getElementById('screen-challenges').classList.remove('hidden');
    document.getElementById('bottom-nav').style.display = 'flex'; // Keep nav visible
    soundManager.play('menu_click');
}

function showHowToPlay() {
    hideAllScreens();
    document.getElementById('screen-help').classList.remove('hidden');
    document.getElementById('bottom-nav').style.display = 'flex';
    updateActiveNav('Help');
}

function showChangelog() {
    hideAllScreens();
    document.getElementById('screen-news').classList.remove('hidden');
    document.getElementById('bottom-nav').style.display = 'flex';
    updateActiveNav('News');
}

function showSettings() {
    hideAllScreens();
    document.getElementById('screen-settings').classList.remove('hidden');
    document.getElementById('bottom-nav').style.display = 'flex';
    updateActiveNav('Settings');

    // Hide back button when opened from main menu (bottom nav provides navigation)
    const backBtn = document.getElementById('settings-back-btn');
    if (backBtn) backBtn.style.display = 'none';

    // Re-bind settings if needed, or ensure they are bound on init
    initSettingsUI();
}

function updateActiveNav(label) {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.querySelector('.nav-label').innerText === label) {
            item.classList.add('active');
        }
    });
}

function initSettingsUI() {
    // Bind events for the static settings screen
    const masterVol = document.getElementById('settings-vol-master');
    const sfxVol = document.getElementById('settings-vol-sfx');
    const musicVol = document.getElementById('settings-vol-music');
    const ghostCheck = document.getElementById('settings-ghost-new');
    const shakeCheck = document.getElementById('settings-shake-new');
    const beamCheck = document.getElementById('settings-beam-new');
    const mouseCheck = document.getElementById('settings-mouse-new');
    const btnControls = document.getElementById('btn-toggle-controls');

    // Set initial values from state/DOM
    if (masterVol) masterVol.value = document.getElementById('vol-master')?.value || 50;
    if (sfxVol) sfxVol.value = document.getElementById('vol-sfx')?.value || 80;
    if (musicVol) musicVol.value = document.getElementById('vol-music')?.value || 30;
    if (ghostCheck) ghostCheck.checked = state.settings.ghostEnabled;
    if (shakeCheck) shakeCheck.checked = state.settings.shakeEnabled;
    if (beamCheck) beamCheck.checked = state.settings.beamEnabled;
    if (mouseCheck) mouseCheck.checked = state.settings.mouseEnabled;
    if (btnControls) btnControls.innerText = state.settings.controlScheme.toUpperCase();

    // Bind listeners
    if (masterVol) masterVol.oninput = () => {
        const val = masterVol.value;
        if (document.getElementById('vol-master')) document.getElementById('vol-master').value = val;
        soundManager.updateVolumes();
    };
    if (sfxVol) sfxVol.oninput = () => {
        const val = sfxVol.value;
        if (document.getElementById('vol-sfx')) document.getElementById('vol-sfx').value = val;
        soundManager.updateVolumes();
    };
    if (musicVol) musicVol.oninput = () => {
        const val = musicVol.value;
        if (document.getElementById('vol-music')) document.getElementById('vol-music').value = val;
        soundManager.updateVolumes();
    };
    if (ghostCheck) ghostCheck.onchange = (e) => {
        state.settings.ghostEnabled = e.target.checked;
        if (document.getElementById('setting-ghost')) document.getElementById('setting-ghost').checked = e.target.checked;
    };
    if (shakeCheck) shakeCheck.onchange = (e) => {
        state.settings.shakeEnabled = e.target.checked;
        if (document.getElementById('setting-shake')) document.getElementById('setting-shake').checked = e.target.checked;
    };
    if (beamCheck) beamCheck.onchange = (e) => {
        state.settings.beamEnabled = e.target.checked;
        if (document.getElementById('setting-beam')) document.getElementById('setting-beam').checked = e.target.checked;
    };
    if (mouseCheck) mouseCheck.onchange = (e) => {
        state.settings.mouseEnabled = e.target.checked;
        if (document.getElementById('setting-mouse')) document.getElementById('setting-mouse').checked = e.target.checked;
        localStorage.setItem('mouseEnabled', e.target.checked);
        updateControlsText();
    };
    if (btnControls) {
        // Set initial state: unchecked = swipe, checked = buttons
        btnControls.checked = (state.settings.controlScheme === 'buttons');

        btnControls.onchange = (e) => {
            state.settings.controlScheme = e.target.checked ? 'buttons' : 'swipe';
            localStorage.setItem('controlScheme', state.settings.controlScheme);

            // Toggle visibility of on-screen buttons
            const mobileControls = document.querySelector('.mobile-controls');
            if (mobileControls) {
                mobileControls.style.display = (state.settings.controlScheme === 'buttons') ? 'flex' : 'none';
            }
        };
    }
}

function updateControlsText() {
    const moveEl = document.getElementById('controls-move');
    const dropEl = document.getElementById('controls-drop');
    const hardDropEl = document.getElementById('controls-hard-drop');
    const holdEl = document.getElementById('controls-hold');

    if (!moveEl || !dropEl || !hardDropEl || !holdEl) return;

    if (state.settings.mouseEnabled) {
        moveEl.innerText = "Mouse Hover";
        dropEl.innerText = "Scroll Wheel";
        hardDropEl.innerText = "Left Click";
        holdEl.innerText = "Right Click";
    } else {
        moveEl.innerText = "Arrow Keys";
        dropEl.innerText = "Down Arrow";
        hardDropEl.innerText = "Space";
        holdEl.innerText = "Shift / C";
    }
}

function closeSettings() {
    showMainMenu();
}

function hideAllScreens() {
    document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
    document.getElementById('overlay').classList.add('hidden');
    document.getElementById('mission-hud').classList.add('hidden');
    document.getElementById('time-attack-hud').classList.add('hidden');
    document.getElementById('game-logo').style.display = 'none';
}

function startGameMode(mode, missionId = null) {
    hideAllScreens();
    soundManager.play('menu_click');
    document.getElementById('bottom-nav').style.display = 'none'; // Hide nav in game

    // Stop menu music with outro
    if (typeof musicManager !== 'undefined') {
        musicManager.stop(true);
    }

    state.gameMode = mode;

    if (mode === 'challenge' && missionId) {
        state.currentMission = MISSIONS.find(m => m.id === missionId);
        state.missionProgress = 0;
        state.missionComplete = false;
        state.missionStartTime = Date.now();

        // Setup HUD
        const hud = document.getElementById('mission-hud');
        hud.classList.remove('hidden');
        updateMissionHUD();
    } else if (mode === 'timeattack') {
        state.timeAttackTimer = 60;
        state.timeAttackStartTime = Date.now();
        document.getElementById('time-attack-hud').classList.remove('hidden');
        updateTimeAttackHUD();
    }

    // Show countdown before starting
    showCountdown(() => {
        startGame();
    });
}

// Countdown function
function showCountdown(callback) {
    const overlay = document.getElementById('countdown-overlay');
    const number = document.getElementById('countdown-number');

    let count = 3;
    overlay.classList.remove('hidden');
    number.textContent = count;

    soundManager.play('menu_click');

    const countdownInterval = setInterval(() => {
        count--;
        if (count > 0) {
            number.textContent = count;
            // Trigger animation by removing and re-adding
            number.style.animation = 'none';
            setTimeout(() => {
                number.style.animation = '';
            }, 10);
            soundManager.play('menu_click');
        } else {
            clearInterval(countdownInterval);
            overlay.classList.add('hidden');
            soundManager.play('drop');

            // Start game music (intro -> loop)
            if (typeof musicManager !== 'undefined') {
                musicManager.play('game');
            }

            callback();
        }
    }, 600); // 600ms per number for a quick countdown
}


function renderMissions() {
    const grid = document.getElementById('mission-grid');
    if (!grid) return;
    grid.innerHTML = '';

    if (!MISSIONS || MISSIONS.length === 0) {
        grid.innerHTML = '<div style="color:#fff; text-align:center; grid-column:1/-1;">No missions loaded.</div>';
        return;
    }

    const completedMissions = JSON.parse(localStorage.getItem('completedMissions') || '[]');

    MISSIONS.forEach(m => {
        const el = document.createElement('div');
        el.className = 'mission-card';
        el.onclick = () => startGameMode('challenge', m.id);

        // Check completion from localStorage
        const completed = completedMissions.includes(m.id);
        if (completed) el.classList.add('completed');

        let color = '#fff';
        try {
            if (typeof getDiffColor === 'function') {
                color = getDiffColor(m.diff);
            }
        } catch (e) { console.warn("getDiffColor failed", e); }

        const stars = (m.diff && typeof m.diff === 'number') ? '★'.repeat(m.diff) : '';

        el.innerHTML = `
            <div class="mission-title">${m.name}</div>
            <div class="mission-desc">${m.desc}</div>
            <div class="mission-status">${completed ? '✅' : '⭕'}</div>
            <div style="margin-top:5px; font-size:10px; color:${color}">
                ${stars}
            </div>
        `;
        grid.appendChild(el);
    });
}

function getDiffColor(d) {
    if (d <= 1) return '#2ecc71';
    if (d <= 3) return '#f1c40f';
    return '#e74c3c';
}

function updateMissionHUD() {
    if (!state.currentMission) return;
    const m = state.currentMission;
    const text = document.getElementById('mission-hud-text');

    let progressStr = '';
    if (m.type === 'timed_blocks' || m.type === 'survival') {
        const timeLeft = Math.max(0, Math.ceil(m.timeLimit - (Date.now() - state.missionStartTime) / 1000));
        progressStr = `${state.missionProgress}/${m.target} (${timeLeft}s)`;
        if (m.type === 'survival') progressStr = `${timeLeft}s left`;
    } else {
        progressStr = `${state.missionProgress}/${m.target}`;
    }

    text.innerText = `${m.desc} : ${progressStr}`;
}

function updateTimeAttackHUD() {
    const display = document.getElementById('time-display');
    display.innerText = Math.ceil(state.timeAttackTimer);
    if (state.timeAttackTimer <= 10) display.classList.add('warning');
    else display.classList.remove('warning');
}

function showTimeBonus(amount) {
    const hud = document.getElementById('time-attack-hud');
    const el = document.createElement('div');
    el.className = 'time-bonus';
    el.innerText = `+${amount}s`;
    el.style.left = `${Math.random() * 40 - 20}px`;
    el.style.top = '0px';
    hud.appendChild(el);
    setTimeout(() => el.remove(), 1000);
}

function resize() {
    if (window.innerWidth < 768) {
        // Dynamic Mobile Sizing
        // Calculate max width based on screen width
        const maxWidth = window.innerWidth - 20;
        const cellWidth = Math.floor(maxWidth / CONFIG.cols);

        // Calculate max height based on screen height
        // Adjusted buffer for fixed bottom HUD
        const availableHeight = window.innerHeight - 120;
        const cellHeight = Math.floor(availableHeight / CONFIG.rows);

        // Use the smaller of the two to ensure it fits
        cellSize = Math.min(cellWidth, cellHeight);

        // Cap it significantly higher (82px) to allow vertical fill
        cellSize = Math.max(30, Math.min(cellSize, 82));

        const holdHint = document.getElementById('hold-hint');
        if (holdHint) holdHint.innerText = "(Tap)";
    } else {
        // Dynamic PC Sizing
        const availableHeight = window.innerHeight - 140;
        cellSize = Math.floor(availableHeight / CONFIG.rows);
        cellSize = Math.min(cellSize, 100);

        const holdHint = document.getElementById('hold-hint');
        if (holdHint) holdHint.innerText = "(Shift/C)";
    }

    canvas.width = CONFIG.cols * cellSize;
    canvas.height = CONFIG.rows * cellSize;

    // Death line is at index 1 of visible rows (so index 3 total)
    // Visible rows start at index 2 (hiddenRows=2)
    const visualRowIndex = 1;
    const pixelOffset = visualRowIndex * cellSize;

    const dl = document.getElementById('death-line-visual');
    dl.style.top = `${pixelOffset}px`;
    dl.style.display = 'block';

    draw();
}

function togglePause() {
    if (state.gameOver || state.gameMode === 'menu') return;

    state.paused = !state.paused;
    const overlay = document.getElementById('overlay');

    if (state.paused) {
        overlay.classList.remove('hidden');
        document.getElementById('overlay-title').innerText = "PAUSED";
        document.getElementById('overlay-score').innerText = "Game Paused";

        // Show Pause Menu Buttons
        document.getElementById('resume-btn').style.display = 'block';
        document.getElementById('start-btn').style.display = 'block';
        document.getElementById('start-btn').innerText = "RESTART";
        document.getElementById('settings-btn').style.display = 'block';
        document.getElementById('menu-btn').style.display = 'block';

    } else {
        overlay.classList.add('hidden');
        state.settingsOpen = false;
        state.pausedBeforeSettings = false;
        // Close settings screen if it's open
        document.getElementById('screen-settings').classList.add('hidden');
    }
}

function setupSettings() {
    const btnPause = document.getElementById('btn-pause');
    const btnBackSettings = document.getElementById('settings-back-btn');
    const sliders = document.querySelectorAll('.setting-slider');

    if (btnPause) {
        btnPause.onclick = () => {
            togglePause();
        };
    }

    // Back button from settings screen
    if (btnBackSettings) {
        btnBackSettings.onclick = () => {
            // If we came from pause menu, go back to it
            if (state.pausedBeforeSettings) {
                hideAllScreens();
                document.getElementById('overlay').classList.remove('hidden');
                document.getElementById('bottom-nav').style.display = 'none';
                state.pausedBeforeSettings = false;
            } else {
                // Otherwise go to main menu
                showMainMenu();
            }
        };
    }

    // Auto-pause on blur
    window.addEventListener('blur', () => {
        if (!state.gameOver && state.activePiece && !state.settingsOpen && state.gameMode !== 'menu' && !state.paused) {
            togglePause();
        }
    });

    sliders.forEach(s => {
        s.oninput = () => soundManager.updateVolumes();
    });

    // Overlay Buttons
    document.getElementById('resume-btn').onclick = () => {
        if (state.paused) togglePause();
    };

    document.getElementById('start-btn').onclick = () => {
        restartGame();
    };

    document.getElementById('settings-btn').onclick = () => {
        // Hide pause overlay and show settings screen
        document.getElementById('overlay').classList.add('hidden');
        document.getElementById('screen-settings').classList.remove('hidden');
        document.getElementById('bottom-nav').style.display = 'none';

        // Show back button when opened from pause menu
        const backBtn = document.getElementById('settings-back-btn');
        if (backBtn) backBtn.style.display = 'block';

        state.settingsOpen = true;
        state.pausedBeforeSettings = true;
    };

    document.getElementById('menu-btn').onclick = () => {
        showMainMenu();
    };

}

function startGame() {
    state.grid = Array(TOTAL_ROWS).fill().map(() => Array(CONFIG.cols).fill(null));
    state.score = 0;
    state.level = 1;
    state.levelScore = 0;
    state.scoreToNext = 1500;
    state.gameOver = false;
    state.paused = false;
    state.particles = [];
    state.trails = []; // Clear trails too
    state.runCores = 0;
    state.comboBest = 0;
    state.lastClearSize = 0;
    state.jackpotMeter = 0;
    state.feverTimer = 0;
    state.payoutFlash = 0;
    state.holdPiece = null;
    state.canHold = true;

    // Initialize Color Pools (Shuffle 1-6)
    const allColors = [1, 2, 3, 4, 5, 6];
    for (let i = allColors.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [allColors[i], allColors[j]] = [allColors[j], allColors[i]];
    }
    state.activeColors = allColors.slice(0, 3);
    state.reserveColors = allColors.slice(3);

    state.nextPiece = generatePiece();
    spawnPiece();

    updateUI();
    document.getElementById('overlay').classList.add('hidden');

    // Reset overlay buttons
    const startBtn = document.getElementById('start-btn');
    const resumeBtn = document.getElementById('resume-btn');
    if (startBtn) startBtn.style.display = 'none';
    if (resumeBtn) resumeBtn.style.display = 'block';
}

function restartGame() {
    if (state.gameMode === 'endless') {
        startGameMode('endless');
    } else if (state.gameMode === 'timeattack') {
        startGameMode('timeattack');
    } else if (state.gameMode === 'challenge' && state.currentMission) {
        startGameMode('challenge', state.currentMission.id);
    }
}

/* --- Game Loop --- */
function gameLoop(time) {
    const dt = time - state.lastTime;
    state.lastTime = time;

    if (!state.paused && !state.gameOver && !state.settingsOpen && state.gameMode !== 'menu') {
        updateLogic(dt);
    }

    draw();
    drawPreview();
    requestAnimationFrame(gameLoop);
}

/* --- Logic --- */

function updateLogic(dt) {
    // --- Visual Updates (Always run, even when locking) ---

    // Particles (Advanced Physics)
    for (let i = state.particles.length - 1; i >= 0; i--) {
        const p = state.particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.45; // Gravity
        p.angle += p.spin; // Rotation
        p.size *= 0.96; // Size decay
        p.life -= 0.025;
        if (p.life <= 0 || p.size < 0.5) state.particles.splice(i, 1);
    }

    // Floating Texts (Smooth Pop & Float)
    for (let i = state.floatingTexts.length - 1; i >= 0; i--) {
        const ft = state.floatingTexts[i];
        ft.y -= 0.85; // Slower float up
        ft.life -= 0.02;
        ft.scale = Math.min(1.2, ft.scale + 0.05); // Pop in effect
        if (ft.life <= 0) state.floatingTexts.splice(i, 1);
    }

    // Trails
    for (let i = state.trails.length - 1; i >= 0; i--) {
        const t = state.trails[i];
        t.life -= t.decay;
        if (t.life <= 0) state.trails.splice(i, 1);
    }

    if (state.feverTimer > 0) {
        state.feverTimer = Math.max(0, state.feverTimer - dt / 1000);
    }

    if (state.payoutFlash > 0) {
        state.payoutFlash = Math.max(0, state.payoutFlash - dt / 1000);
    }

    // --- Game Logic (Paused when locking) ---
    if (state.locking) return;

    // Time Attack Timer
    if (state.gameMode === 'timeattack' && state.timeAttackTimer > 0) {
        state.timeAttackTimer -= dt / 1000;
        if (state.timeAttackTimer <= 0) {
            state.timeAttackTimer = 0;
            triggerGameOver();
        }
        updateTimeAttackHUD();
    }

    // Timed Missions
    if (state.gameMode === 'challenge' && state.currentMission) {
        const m = state.currentMission;
        if (m.type === 'timed_blocks' || m.type === 'survival') {
            const elapsed = (Date.now() - state.missionStartTime) / 1000;
            if (elapsed >= m.timeLimit) {
                if (m.type === 'survival' || state.missionProgress < m.target) {
                    failMission();
                }
            }
            updateMissionHUD();
        }
    }

    // Interpolation
    if (state.activePiece) {
        // Time-based Lerp for consistent smoothness regardless of framerate
        // Formula: current = target - (target - current) * exp(-speed * dt)
        const speed = 0.015; // Adjusted for ms
        const t = 1 - Math.exp(-speed * dt);

        state.activePiece.renderX += (state.activePiece.x - state.activePiece.renderX) * t;
        state.activePiece.renderY += (state.activePiece.y - state.activePiece.renderY) * t;
    }

    // Drop Speed
    state.dropTimer += dt;
    // Slower start, speeds up more aggressively
    const currentInterval = Math.max(150, CONFIG.dropIntervalStart - ((state.level - 1) * 100));

    if (state.dropTimer > currentInterval) {
        state.dropTimer = 0;
        movePiece(0, 1);
    }
}

function rotatePiece() {
    if (!state.activePiece || state.locking || state.paused) return;

    const p = state.activePiece;
    // Only Metal blocks have rotation (Directional)
    if (p.type === 'metal') {
        const newDir = (p.dir === 0) ? 1 : 0;
        p.dir = newDir;
        soundManager.play('move');
    }
}

function movePiece(dx, dy) {
    if (state.locking) return;

    if (!checkCollision(dx, dy)) {
        state.activePiece.x += dx;
        state.activePiece.y += dy;
        // state.activePiece.renderX = state.activePiece.x; // Removed for smooth drop
        // state.activePiece.renderY = state.activePiece.y; // Removed for smooth drop

        if (dx !== 0) {
            soundManager.play('move');
            hapticManager.light(); // Light vibration for horizontal movement
        }
        if (dy > 0) state.score += 1; // Soft drop points
        return true;
    } else if (dy > 0) {
        lockPiece();
        return false;
    }
    return false;
}

function hardDrop() {
    if (state.locking) return;

    hapticManager.strong(); // Strong vibration for hard drop

    // Beam Effect (Visual Trail)
    if (state.settings.beamEnabled) {
        const p = state.activePiece;
        // Calculate drop distance for beam height
        let dropDist = 0;
        let ghostY = p.y;
        while (!checkCollision(0, 1, { ...p, y: ghostY })) {
            ghostY++;
            dropDist++;
        }

        if (dropDist > 0) {
            state.trails.push({
                x: p.x,
                y: p.y, // Start from current position
                h: dropDist, // Height is distance to bottom
                color: p.color,
                life: 1.0,
                decay: 0.1 // Fast fade
            });
        }
    }

    let dropped = 0;
    while (!checkCollision(0, 1)) {
        state.activePiece.y++;
        dropped++;
    }
    state.activePiece.renderY = state.activePiece.y;
    state.score += dropped * 2;
    soundManager.play('drop');

    // Subtle Screen Shake
    if (state.settings.shakeEnabled) {
        const canvas = document.getElementById('game-canvas');
        canvas.classList.remove('shake-subtle'); // Reset animation
        void canvas.offsetWidth; // Trigger reflow
        canvas.classList.add('shake-subtle');
        setTimeout(() => canvas.classList.remove('shake-subtle'), 200);
    }

    lockPiece();
}

function checkCollision(dx, dy, piece = state.activePiece) {
    if (!piece) return false;
    const nx = piece.x + dx;
    const ny = piece.y + dy;

    if (nx < 0 || nx >= CONFIG.cols || ny >= TOTAL_ROWS) return true;
    if (ny < 0) return false; // Above board is fine

    if (state.grid[ny][nx]) return true;
    return false;
}

function getGhostPosition() {
    if (!state.activePiece) return null;
    let ghost = { ...state.activePiece };
    while (!checkCollision(0, 1, ghost)) {
        ghost.y++;
    }
    return ghost;
}

function holdPiece() {
    if (!state.canHold || state.locking || state.gameOver) return;

    if (!state.holdPiece) {
        state.holdPiece = { ...state.activePiece };
        state.activePiece = null;
        spawnPiece();
    } else {
        const temp = { ...state.activePiece };
        state.activePiece = { ...state.holdPiece, x: 2, y: CONFIG.hiddenRows };
        state.holdPiece = temp;
        state.activePiece.renderX = 2;
        state.activePiece.renderY = CONFIG.hiddenRows;
    }

    state.canHold = false;
    soundManager.play('move');
}

async function lockPiece() {
    const p = state.activePiece;
    if (!p) return;

    state.locking = true;
    hapticManager.medium(); // Medium vibration for piece placement

    // Lock into grid. Drill spends itself immediately so it does not consume
    // one of the cells it is supposed to bore through.
    if (p.type !== 'drill') {
        state.grid[p.y][p.x] = {
            type: p.type,
            color: p.color,
            id: p.id,
            dir: p.dir
        };
    }

    soundManager.play('drop');
    state.activePiece = null;
    state.canHold = true;

    // Check for Drill/Bomb usage for missions
    if (state.gameMode === 'challenge' && state.currentMission) {
        if (p.type === 'drill') updateMissionProgress('drill', 1);
        if (p.type === 'bomb') updateMissionProgress('bomb', 1);
    }

    // Time Attack Bonus for Special Pieces
    if (state.gameMode === 'timeattack') {
        if (p.type === 'drill' || p.type === 'bomb') {
            state.timeAttackTimer += 2;
            showTimeBonus(2);
        }
    }

    const wasDrill = (p.type === 'drill');
    const wasBomb = (p.type === 'bomb');

    if (wasDrill) {
        fireDrill(p.x, p.y);
        await processMatches(false);
    } else {
        await processMatches(wasBomb);
    }

    state.locking = false;
    spawnPiece();
}

async function processMatches(triggerBombs) {
    let settling = true;
    let chain = 0;
    let settlePasses = 0;
    const MAX_SETTLE_PASSES = 40;

    if (triggerBombs) {
        if (handleExplosions()) {
            await new Promise(r => setTimeout(r, 250));
        }
    }

    while (settling) {
        settlePasses++;
        if (settlePasses > MAX_SETTLE_PASSES) {
            console.warn('ClusterCore: aborted match settling loop after max passes.');
            break;
        }

        applyGravity();

        const matches = findMatches();

        if (matches.length > 0) {
            const feverMult = state.feverTimer > 0 ? 2 : 1;
            let points = Math.floor(matches.length * 150 * (chain + 1) * feverMult * (1 + getUpgradeLevel('magnet') * 0.08));

            // Mission Progress
            if (state.gameMode === 'challenge' && state.currentMission) {
                updateMissionProgress('blocks', matches.length);

                // Check for color matches
                const colorCounts = {};
                matches.forEach(m => {
                    const c = state.grid[m.y][m.x];
                    if (c) colorCounts[c.id] = (colorCounts[c.id] || 0) + 1;
                });

                const m = state.currentMission;
                if (m.type === 'color' && colorCounts[m.colorId]) {
                    updateMissionProgress('color', 1);
                }

                // Check for Diagonal Lines (Staircase pattern in cluster)
                if (m.type === 'diagonal') {
                    const matchSet = new Set(matches.map(b => `${b.x},${b.y}`));
                    let hasDiagonal = false;

                    for (const b of matches) {
                        // Check Down-Right (x+1, y+1)
                        if (matchSet.has(`${b.x + 1},${b.y + 1}`) &&
                            matchSet.has(`${b.x + 2},${b.y + 2}`) &&
                            matchSet.has(`${b.x + 3},${b.y + 3}`)) {
                            hasDiagonal = true;
                            break;
                        }
                        // Check Up-Right (x+1, y-1)
                        if (matchSet.has(`${b.x + 1},${b.y - 1}`) &&
                            matchSet.has(`${b.x + 2},${b.y - 2}`) &&
                            matchSet.has(`${b.x + 3},${b.y - 3}`)) {
                            hasDiagonal = true;
                            break;
                        }
                    }

                    if (hasDiagonal) {
                        updateMissionProgress('diagonal', 1);
                    }
                }
            }

            // Time Attack Bonus
            if (state.gameMode === 'timeattack') {
                let bonus = 0;
                if (matches.length >= 4) bonus += 1;
                if (matches.length >= 8) bonus += 2;
                if (chain > 0) bonus += 1;
                if (bonus > 0) {
                    state.timeAttackTimer += bonus;
                    showTimeBonus(bonus);
                }
            }

            // Clear matched blocks from grid
            let clearedCount = 0;
            matches.forEach(m => {
                const cell = state.grid[m.y][m.x];
                if (!cell) return;
                spawnParticles(m.x, m.y, cell.color || m.color);
                state.grid[m.y][m.x] = null;
                clearedCount++;
            });

            // Safety: avoid endless chains if a stale match list cannot mutate the grid.
            if (clearedCount === 0) {
                console.warn('ClusterCore: matches found but no blocks cleared. Stopping settle loop.');
                break;
            }

            addScore(points);
            awardCoreShards(points, matches.length, chain);
            chargeJackpot(matches.length, chain);
            soundManager.play('match', chain);
            
            // Visuals
            if (chain > 0 || points > 300) {
                const first = matches[0];
                const cx = first.x * cellSize + cellSize / 2;
                const cy = (first.y - CONFIG.hiddenRows) * cellSize + cellSize / 2;
                if (chain > 0) spawnFloatingText(cx, cy - 20, `x${chain + 1}`, '#FFD700', 24);

                const praise = getPraiseWord(points);
                // Spawn praise text in the center of the screen
                spawnFloatingText(canvas.width / 2, canvas.height / 2, state.feverTimer > 0 ? `${t('fever')} ${praise.text}` : praise.text, praise.color, praise.size);
            }

            // Dynamic Screen Shake based on cluster size
            if (state.settings.shakeEnabled) {
                if (matches.length >= 8 || chain > 1) {
                    canvas.classList.remove('shake');
                    void canvas.offsetWidth; // Trigger reflow
                    canvas.classList.add('shake');
                } else {
                    canvas.classList.remove('shake-subtle');
                    void canvas.offsetWidth; // Trigger reflow
                    canvas.classList.add('shake-subtle');
                }
            }

            hapticManager.medium(); // Vibrate when clearing blocks
            chain++;
            state.comboBest = Math.max(state.comboBest, chain);
            updateMissionProgress('combo', chain);
            updateUI();
            await new Promise(r => setTimeout(r, 250));
        } else {
            settling = false;
        }
    }
}

function fireDrill(col, startY = 0) {
    let destroyedCount = 0;
    const drillLevel = getUpgradeLevel('drillBore');
    const maxDepth = Math.min(TOTAL_ROWS, 6 + (drillLevel * 2));
    const firstVisibleY = Math.max(0, startY);
    hapticManager.drill(); // Drill haptic pattern

    state.trails.push({
        x: col,
        y: CONFIG.hiddenRows,
        h: CONFIG.rows,
        color: CONFIG.colors.laser,
        life: 1.0,
        decay: 0.055
    });

    for (let y = firstVisibleY; y < TOTAL_ROWS && destroyedCount < maxDepth; y++) {
        const cell = state.grid[y][col];
        if (cell && cell.type !== 'dead') {
            spawnParticles(col, y, cell.color || CONFIG.colors.laser);
            state.grid[y][col] = null;
            destroyedCount++;
        }
    }

    if (destroyedCount > 0) {
        const points = Math.floor(destroyedCount * 125 * (1 + drillLevel * 0.15));
        addScore(points);
        awardCoreShards(points, destroyedCount, 1 + drillLevel);
        chargeJackpot(destroyedCount + 2, 1 + drillLevel);
        spawnFloatingText(
            col * cellSize + cellSize / 2,
            Math.max(cellSize, (startY - CONFIG.hiddenRows) * cellSize),
            `${t('drill')} +${points}`,
            '#FFFFFF',
            24
        );
    } else {
        spawnFloatingText(col * cellSize + cellSize / 2, canvas.height / 2, t('drill'), '#FFFFFF', 24);
    }

    applyGravity();
    soundManager.play('laser');
    canvas.classList.add('shake');
    setTimeout(() => canvas.classList.remove('shake'), 300);
    updateUI();
}

function updateMissionProgress(type, value) {
    if (!state.currentMission || state.missionComplete) return;
    const m = state.currentMission;

    if (m.type === type) {
        state.missionProgress += value;
        updateMissionHUD();

        if (m.type !== 'survival' && state.missionProgress >= m.target) {
            completeMission();
        }
    }
}

function completeMission() {
    state.missionComplete = true;
    state.paused = true;
    soundManager.play('success');

    // Save completion to localStorage
    const completedMissions = JSON.parse(localStorage.getItem('completedMissions') || '[]');
    if (!completedMissions.includes(state.currentMission.id)) {
        completedMissions.push(state.currentMission.id);
        localStorage.setItem('completedMissions', JSON.stringify(completedMissions));
    }

    document.getElementById('overlay-title').innerText = "MISSION COMPLETE";
    document.getElementById('overlay-score').innerText = state.currentMission.name;

    const startBtn = document.getElementById('start-btn');
    const resumeBtn = document.getElementById('resume-btn');
    if (startBtn) {
        startBtn.innerText = "CONTINUE";
        startBtn.onclick = () => {
            renderMissions(); // Refresh mission display
            showChallengeSelect();
        };
        startBtn.style.display = 'block';
    }
    if (resumeBtn) resumeBtn.style.display = 'none';

    document.getElementById('overlay').classList.remove('hidden');
}

function failMission() {
    state.missionComplete = true;
    state.paused = true;
    soundManager.play('gameover');
    document.getElementById('overlay-title').innerText = "MISSION FAILED";
    document.getElementById('overlay-score').innerText = "Time's Up!";

    const startBtn = document.getElementById('start-btn');
    const resumeBtn = document.getElementById('resume-btn');
    if (startBtn) {
        startBtn.innerText = "RETRY";
        startBtn.onclick = () => startGameMode('challenge', state.currentMission.id);
        startBtn.style.display = 'block';
    }
    if (resumeBtn) resumeBtn.style.display = 'none';

    document.getElementById('overlay').classList.remove('hidden');
}



function generatePiece() {
    // Independent rolls for special pieces to avoid overlap issues
    const capacitor = getUpgradeLevel('capacitor');
    const specialBoost = capacitor * 0.006;

    // Dead Metal (Starts Level 5, 10% chance)
    if (state.level >= 5 && Math.random() < 0.10) {
        return { type: 'dead', color: CONFIG.colors.dead, dir: 0, id: 999 };
    }

    // Bomb Chance (2% + level scaling)
    if (Math.random() < 0.02 + (state.level * 0.005) + specialBoost) {
        return { type: 'bomb', color: CONFIG.colors.bomb, dir: 0, id: 888 };
    }

    // Drill Chance (Starts Level 1, 1.5% chance + scaling)
    if (state.level >= 1 && Math.random() < 0.02 + (state.level * 0.003) + specialBoost) {
        return { type: 'drill', color: '#C0C0C0', dir: 0, id: 777 };
    }

    // Metal Arrow Chance (15%)
    if (Math.random() < 0.15) {
        const colorId = state.activeColors[Math.floor(Math.random() * state.activeColors.length)];
        const color = CONFIG.colors[colorId];
        const dir = Math.random() > 0.5 ? 1 : 0; // 0: Horiz, 1: Vert
        return { type: 'metal', color: color, dir: dir, id: colorId };
    }

    // Normal Piece
    const colorId = state.activeColors[Math.floor(Math.random() * state.activeColors.length)];
    const color = CONFIG.colors[colorId];
    return { type: 'normal', color: color, dir: 0, id: colorId };
}

function spawnPiece() {
    const p = state.nextPiece;
    // Determine spawn column: use cursor position if mouse controls enabled, else middle
    let spawnX = 2; // Default middle column
    if (state.settings.mouseEnabled && state.lastMouseColumn !== null) {
        spawnX = Math.max(0, Math.min(CONFIG.cols - 1, state.lastMouseColumn));
    }

    state.activePiece = {
        x: spawnX,
        y: CONFIG.hiddenRows,
        renderX: spawnX,
        renderY: CONFIG.hiddenRows,
        type: p.type,
        color: p.color,
        dir: p.dir,
        id: p.id
    };

    state.nextPiece = generatePiece();
    state.dropTimer = 0;

    if (checkCollision(0, 0)) {
        state.activePiece = null;
        triggerGameOver();
        return;
    }

    // Death Line Check
    for (let x = 0; x < CONFIG.cols; x++) {
        if (state.grid[CONFIG.hiddenRows][x] !== null) {
            triggerGameOver();
            return;
        }
    }
}

function applyGravity() {
    for (let x = 0; x < CONFIG.cols; x++) {
        for (let y = TOTAL_ROWS - 2; y >= 0; y--) {
            if (state.grid[y][x] !== null) {
                let dy = y;
                while (dy + 1 < TOTAL_ROWS && state.grid[dy + 1][x] === null) {
                    state.grid[dy + 1][x] = state.grid[dy][x];
                    state.grid[dy][x] = null;
                    dy++;
                }
            }
        }
    }
}

function handleExplosions() {
    let hit = false;
    for (let y = 0; y < TOTAL_ROWS; y++) {
        for (let x = 0; x < CONFIG.cols; x++) {
            if (state.grid[y][x] && state.grid[y][x].type === 'bomb') {
                hit = true;
                explode(x, y);
            }
        }
    }
    return hit;
}

function explode(cx, cy) {
    state.grid[cy][cx] = null;
    spawnParticles(cx, cy, CONFIG.colors.bomb);
    soundManager.play('explode');
    hapticManager.explosion(); // Explosion haptic pattern

    // Bomb Nerf: Plus shape only (Up, Down, Left, Right)
    const dirs = [[0, 1], [0, -1], [1, 0], [-1, 0]];

    dirs.forEach(([dx, dy]) => {
        let ny = cy + dy, nx = cx + dx;
        if (ny >= 0 && ny < TOTAL_ROWS && nx >= 0 && nx < CONFIG.cols) {
            if (state.grid[ny][nx] && state.grid[ny][nx].type !== 'dead') { // Dead blocks are invincible
                spawnParticles(nx, ny, state.grid[ny][nx].color);
                state.grid[ny][nx] = null;
                addScore(50);
            }
        }
    });
    canvas.classList.add('shake');
    setTimeout(() => canvas.classList.remove('shake'), 500);
}

function spawnParticles(gx, gy, color) {
    const cx = gx * cellSize + cellSize / 2;
    const cy = (gy - CONFIG.hiddenRows) * cellSize + cellSize / 2;

    for (let i = 0; i < 12; i++) {
        state.particles.push({
            x: cx, y: cy,
            vx: (Math.random() - 0.5) * 14,
            vy: (Math.random() - 0.7) * 14, // Slight upward bias
            size: Math.random() * 8 + 3,
            angle: Math.random() * Math.PI * 2,
            spin: (Math.random() - 0.5) * 0.3,
            color: color,
            life: 1.0
        });
    }
}

function spawnFloatingText(x, y, text, color, size = 32) {
    state.floatingTexts.push({
        x, y, text, color, size, life: 1.0, scale: 0.5
    });
}

function awardCoreShards(points, clearSize, chain) {
    const modeBonus = state.gameMode === 'challenge' ? 1.25 : state.gameMode === 'timeattack' ? 1.15 : 1;
    const comboBonus = Math.max(0, chain) * 0.25;
    const feverBonus = state.feverTimer > 0 ? 1.5 : 1;
    const amount = Math.max(1, Math.floor((points / 650 + clearSize / 8) * (modeBonus + comboBonus) * feverBonus));

    state.runCores += amount;
    state.meta.cores += amount;
    state.meta.totalCores += amount;
    saveMeta();

    if (amount > 0) {
        spawnFloatingText(canvas.width / 2, canvas.height * 0.34, `+${amount} ${t('shardBurst')}`, '#66D9E8', 24);
    }

    renderMetaUI();
}

function chargeJackpot(clearSize, chain) {
    const gain = clearSize * 4 + Math.max(0, chain) * 10;
    state.jackpotMeter = Math.min(100, state.jackpotMeter + gain);

    if (state.jackpotMeter >= 100) {
        state.jackpotMeter = 0;
        state.feverTimer = 12;
        state.payoutFlash = 1.2;
        soundManager.play('success');
        hapticManager.success();
        spawnFloatingText(canvas.width / 2, canvas.height * 0.28, t('feverReady'), '#FFD700', 42);
    }

    renderMetaUI();
}

function findMatches() {
    if (!window.ClusterCoreMatchEngine || typeof window.ClusterCoreMatchEngine.findMatchesInGrid !== 'function') {
        return [];
    }

    const matches = window.ClusterCoreMatchEngine.findMatchesInGrid(state.grid, CONFIG, TOTAL_ROWS);
    return matches.map(m => ({
        x: m.x,
        y: m.y,
        color: state.grid[m.y] && state.grid[m.y][m.x] ? state.grid[m.y][m.x].color : null
    }));
}

function getPraiseWord(points) {
    let words = [];
    let color = '#FFF';
    let size = 32;

    if (points < 500) {
        words = ['NICE', 'GOOD', 'COOL', 'NEAT'];
        color = '#FFFFFF';
        size = 24;
    } else if (points < 1500) {
        words = ['SWEET!', 'AWESOME!', 'GREAT!', 'SOLID!'];
        color = '#FFFFFF';
        size = 32;
    } else if (points < 3000) {
        words = ['AMAZING!', 'EPIC!', 'WILD!', 'SUPER!'];
        color = '#FFFFFF';
        size = 40;
    } else {
        words = ['INCREDIBLE!', 'GENIUS!', 'CLUSTER CORE!', 'UNREAL!'];
        color = '#FFFFFF';
        size = 52;
    }

    return {
        text: words[Math.floor(Math.random() * words.length)],
        color: color,
        size: size
    };
}

function addScore(pts) {
    state.score += pts;
    state.levelScore += pts;
    if (state.levelScore >= state.scoreToNext) {
        state.level++;
        state.levelScore = 0;
        state.scoreToNext = Math.floor(state.scoreToNext * 1.5);
        spawnFloatingText(canvas.width / 2, canvas.height / 2 - 70, `${t('levelUp')} ${state.level}`, '#66D9E8', 34);
        updateMissionProgress('level', state.level);

        // Rotate Colors every level (starting at level 2)
        if (state.level > 1) {
            rotateColors();
        }
    }
}

function rotateColors() {
    if (state.reserveColors.length === 0) return;

    const activeIndex = Math.floor(Math.random() * state.activeColors.length);
    const reserveIndex = Math.floor(Math.random() * state.reserveColors.length);

    const oldColorId = state.activeColors[activeIndex];
    const newColorId = state.reserveColors[reserveIndex];

    // Swap
    state.activeColors[activeIndex] = newColorId;
    state.reserveColors[reserveIndex] = oldColorId;

    // Visual Notification
    spawnFloatingText(canvas.width / 2, canvas.height / 2 - 50, "COLOR SWAP!", "#FFD700", 40);
    // soundManager.play('levelup'); // Optional: Add specific sound
}

function triggerGameOver() {
    state.gameOver = true;
    state.paused = true;
    soundManager.play('gameover');
    state.meta.bestScore = Math.max(state.meta.bestScore || 0, state.score);
    saveMeta();
    renderMetaUI();

    // Stop game music and play gameover jingle
    if (typeof musicManager !== 'undefined') {
        musicManager.stop();
        musicManager.play('gameover');
    }

    // Show Ad on Game Over
    if (typeof adManager !== 'undefined') {
        adManager.showInterstitial();
    }

    document.getElementById('overlay-title').innerText = t('coreFailure');
    document.getElementById('overlay-score').innerText = `${t('finalScore')}: ${state.score} | +${state.runCores} ${t('shards')}`;

    document.getElementById('overlay').classList.remove('hidden');

    // Game Over Menu: RESTART, MENU (Hide Resume, Settings)
    document.getElementById('resume-btn').style.display = 'none';
    document.getElementById('settings-btn').style.display = 'none';

    const startBtn = document.getElementById('start-btn');
    startBtn.style.display = 'block';
    startBtn.innerText = "RESTART";

    document.getElementById('menu-btn').style.display = 'block';
}

function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw Grid
    for (let y = CONFIG.hiddenRows; y < TOTAL_ROWS; y++) {
        for (let x = 0; x < CONFIG.cols; x++) {
            const cell = state.grid[y][x];
            if (cell) {
                drawCell(ctx, x, y - CONFIG.hiddenRows, cell);
            }
        }
    }

    // Active Piece
    if (state.activePiece) {
        const pulse = (Math.sin(Date.now() / 200) * 0.15) + 0.85; // Pulse between 0.7 and 1.0

        // Draw Ghost Piece
        if (state.settings.ghostEnabled) {
            const ghost = getGhostPosition();
            if (ghost && ghost.y > state.activePiece.y) {
                if (ghost.y >= CONFIG.hiddenRows - 1) {
                    drawCell(ctx, ghost.x, ghost.y - CONFIG.hiddenRows, { ...ghost, isGhost: true });
                }
            }
        }

        // Draw Active Piece with smooth interpolation and pulse
        if (state.activePiece.renderY >= CONFIG.hiddenRows - 1) {
            const renderX = state.activePiece.renderX || state.activePiece.x;
            const renderY = state.activePiece.renderY || state.activePiece.y;
            ctx.save();
            ctx.globalAlpha = pulse;
            drawCell(ctx, renderX, renderY - CONFIG.hiddenRows, state.activePiece, true); // Pass isActive=true
            ctx.restore();
        }
    }

    // Particles (Optimized Batch Rendering)
    ctx.globalCompositeOperation = 'lighter';

    // Group particles by color
    const particlesByColor = {};
    state.particles.forEach(p => {
        if (!particlesByColor[p.color]) particlesByColor[p.color] = [];
        particlesByColor[p.color].push(p);
    });

    for (const color in particlesByColor) {
        ctx.fillStyle = color;
        ctx.beginPath();
        particlesByColor[color].forEach(p => {
            // Use rects for faster rendering than arcs
            // ctx.rect(p.x - p.size/2, p.y - p.size/2, p.size, p.size);
            // Or keep arcs if preferred, but batched:
            ctx.moveTo(p.x, p.y);
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        });
        // We need to handle alpha per particle? 
        // Batching makes per-particle alpha hard if we use one fill().
        // Actually, particles have 'life' which is alpha. 
        // If we batch, we lose individual alpha unless we group by alpha too, which is too much.
        // Compromise: Use globalAlpha = 1 and modify color? Or just group by rounded alpha?
        // Or... just don't batch color, but avoid beginPath() for every single one if possible?
        // No, beginPath is needed for new shapes usually.
        // Wait, the "lag" is likely the sheer number of context calls.
        // Let's try a different approach: Group by color, and assume average alpha or just use opacity in color string?
        // Simpler optimization: Reduce count (done below) and use squares (rect) without beginPath for each?
        // Actually, let's just use the reduced count first and see. 
        // But for batching:
        // If we want individual alpha, we can't batch easily with one draw call unless we use a shader (WebGL).
        // In 2D Canvas, we can iterate but minimize state changes.
    }

    // Particles (Sparkles)
    state.particles.forEach(p => {
        ctx.globalAlpha = p.life;
        ctx.fillStyle = p.color;
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.angle);
        
        // Draw a 4-pointed sparkle star
        ctx.beginPath();
        for (let i = 0; i < 4; i++) {
            ctx.rotate(Math.PI / 2);
            ctx.lineTo(p.size, 0);
            ctx.lineTo(0, p.size / 4);
        }
        ctx.closePath();
        ctx.fill();
        ctx.restore();
    });

    // Trails
    state.trails.forEach(t => {
        ctx.save();
        ctx.globalAlpha = t.life * 0.6; // Max opacity 0.6
        // Gradient for the beam
        const x = t.x * cellSize;
        const y = (t.y - CONFIG.hiddenRows) * cellSize;
        const h = t.h * cellSize;

        // Only draw if visible
        if (y + h > 0) {
            const grad = ctx.createLinearGradient(x, y, x, y + h);
            grad.addColorStop(0, 'rgba(255,255,255,0)');
            grad.addColorStop(0.5, t.color);
            grad.addColorStop(1, t.color);

            ctx.fillStyle = grad;
            ctx.fillRect(x, y, cellSize, h);
        }
        ctx.restore();
    });
    // Floating Texts (with Pop Scale)
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    state.floatingTexts.forEach(ft => {
        ctx.save();
        ctx.globalAlpha = ft.life;
        ctx.translate(ft.x, ft.y);
        ctx.scale(ft.scale, ft.scale);
        
        ctx.fillStyle = ft.color;
        ctx.font = `bold ${ft.size}px "Fredoka One"`;
        ctx.strokeStyle = 'black';
        ctx.lineWidth = 3;
        ctx.strokeText(ft.text, 0, 0);
        ctx.fillText(ft.text, 0, 0);
        ctx.restore();
    });

    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
}

function drawPieceGlyph(context, pieceId, size, fillStyle = 'rgba(0, 0, 0, 0.15)') {
    if (window.ClusterCoreRenderUtils && typeof window.ClusterCoreRenderUtils.drawPieceGlyph === 'function') {
        window.ClusterCoreRenderUtils.drawPieceGlyph(context, pieceId, size, fillStyle);
    }
}

function applyTextSystem() {
    document.querySelectorAll('[data-text-key]').forEach(el => {
        el.textContent = t(el.dataset.textKey);
    });
}

function renderMetaUI() {
    const shardEls = document.querySelectorAll('[data-core-shards]');
    shardEls.forEach(el => {
        el.textContent = state.meta.cores;
    });

    const bestEls = document.querySelectorAll('[data-best-score]');
    bestEls.forEach(el => {
        el.textContent = state.meta.bestScore;
    });

    const runEls = document.querySelectorAll('[data-run-cores]');
    runEls.forEach(el => {
        el.textContent = state.runCores;
    });

    const comboEls = document.querySelectorAll('[data-best-combo]');
    comboEls.forEach(el => {
        el.textContent = `${state.comboBest}x`;
    });

    const shop = document.getElementById('upgrade-list');
    if (!shop) return;

    shop.innerHTML = '';
    Object.entries(META_UPGRADES).forEach(([id, up]) => {
        const level = getUpgradeLevel(id);
        const maxed = level >= up.max;
        const cost = getUpgradeCost(id);
        const item = document.createElement('div');
        item.className = 'upgrade-row';

        const copy = document.createElement('div');
        copy.className = 'upgrade-copy';
        copy.innerHTML = `
            <div class="upgrade-title">${t(up.nameKey)} <span>${level}/${up.max}</span></div>
            <div class="upgrade-desc">${t(up.descKey)}</div>
        `;

        const button = document.createElement('button');
        button.className = 'upgrade-buy';
        button.disabled = maxed || state.meta.cores < cost;
        button.textContent = maxed ? t('maxed') : `${t('buy')} ${cost}`;
        button.onclick = () => buyUpgrade(id);

        item.appendChild(copy);
        item.appendChild(button);
        shop.appendChild(item);
    });
}

function buyUpgrade(id) {
    const up = META_UPGRADES[id];
    if (!up) return;

    const level = getUpgradeLevel(id);
    if (level >= up.max) return;

    const cost = getUpgradeCost(id);
    if (state.meta.cores < cost) {
        spawnFloatingText(canvas.width / 2, canvas.height / 2, t('notEnough'), '#FF6B6B', 24);
        return;
    }

    state.meta.cores -= cost;
    state.meta.upgrades[id] = level + 1;
    saveMeta();
    soundManager.play('success');
    spawnFloatingText(canvas.width / 2, canvas.height / 2, t('purchased'), '#66D9E8', 28);
    renderMetaUI();
}


function drawCell(context, x, y, cell, isActive = false) {
    const cx = x * cellSize + cellSize / 2;
    const cy = y * cellSize + cellSize / 2;
    const s = cellSize * 0.9;
    const br = 10; // border radius

    context.save();
    context.translate(cx, cy);

    if (cell.isGhost) {
        const gx = -s / 2 + 2;
        const gy = -s / 2 + 2;
        const gs = s - 4;

        // Rounded shadow body that mirrors the live piece style.
        context.globalAlpha = 0.18;
        context.fillStyle = cell.color;
        context.beginPath();
        context.roundRect(gx, gy, gs, gs, br);
        context.fill();

        // Soft border and top highlight for the polished "shadow" look.
        context.globalAlpha = 0.5;
        context.strokeStyle = cell.color;
        context.lineWidth = 2;
        context.beginPath();
        context.roundRect(gx, gy, gs, gs, br);
        context.stroke();

        context.globalAlpha = 0.24;
        context.fillStyle = '#FFFFFF';
        context.beginPath();
        context.roundRect(gx + 3, gy + 3, gs - 6, gs * 0.28, 6);
        context.fill();

        // Keep the same identity shape language as live blocks.
        context.globalAlpha = 0.65;
        drawPieceGlyph(context, cell.id, s, 'rgba(255, 255, 255, 0.55)');

        context.restore();
        return;
    }

    // Shadow for depth
    context.shadowColor = 'rgba(0,0,0,0.3)';
    context.shadowBlur = 8;
    context.shadowOffsetY = 4;

    context.fillStyle = cell.color;
    context.beginPath();

    // Dead Metal visual (Blocky, concrete)
    if (cell.type === 'dead') {
        context.rect(-s / 2, -s / 2, s, s);
        context.fill();
        context.strokeStyle = '#333';
        context.lineWidth = 2;
        context.stroke();

        // Thick X pattern (Old Yellow Style)
        const sz = s * 0.4;
        context.beginPath();
        context.moveTo(-sz, -sz); context.lineTo(sz, sz);
        context.moveTo(sz, -sz); context.lineTo(-sz, sz);
        context.strokeStyle = 'rgba(0,0,0,0.4)'; // Darker for dead block
        context.lineWidth = 5; // Thick
        context.stroke();
    }
    // Standard rounded rect with depth polish
    else if (cell.type !== 'drill') {
        context.roundRect(-s/2, -s/2, s, s, br);
        context.fill();

        // Inner Gem Glow (Center brightness)
        const gemGrad = context.createRadialGradient(0, 0, 0, 0, 0, s/2);
        gemGrad.addColorStop(0, 'rgba(255,255,255,0.25)');
        gemGrad.addColorStop(1, 'rgba(255,255,255,0)');
        context.fillStyle = gemGrad;
        context.roundRect(-s/2, -s/2, s, s, br);
        context.fill();

        // Top Highlight (Surface shine)
        context.fillStyle = 'rgba(255,255,255,0.2)';
        context.roundRect(-s/2 + 3, -s/2 + 3, s - 6, s * 0.3, 6);
        context.fill();

        // Accessibility Shapes (Watermark style - centered)
        drawPieceGlyph(context, cell.id, s);
    }

    // Metal Arrow (Flat white style)
    if (cell.type === 'metal') {
        context.strokeStyle = 'rgba(255,255,255,0.9)';
        context.lineWidth = 5;
        context.lineCap = 'round';
        context.lineJoin = 'round';
        context.beginPath();
        if (cell.dir === 0) { // Horiz
            context.moveTo(-s / 3, 0); context.lineTo(s / 3, 0);
            context.moveTo(s / 6, -s / 6); context.lineTo(s / 3, 0); context.lineTo(s / 6, s / 6);
            context.moveTo(-s / 6, -s / 6); context.lineTo(-s / 3, 0); context.lineTo(-s / 6, s / 6);
        } else { // Vert
            context.moveTo(0, -s / 3); context.lineTo(0, s / 3);
            context.moveTo(-s / 6, s / 6); context.lineTo(0, s / 3); context.lineTo(s / 6, s / 6);
            context.moveTo(-s / 6, -s / 6); context.lineTo(0, -s / 3); context.lineTo(s / 6, -s / 6);
        }
        context.stroke();
    }

    if (cell.type === 'bomb') {
        context.fillStyle = '#111';
        context.beginPath();
        context.arc(0, 0, s / 2.5, 0, Math.PI * 2);
        context.fill();
        context.fillStyle = '#FF4757';
        context.font = 'bold 24px sans-serif';
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        context.fillText('!', 0, 1);

        // Red pulsing ring
        const time = Date.now() / 150;
        context.strokeStyle = `rgba(255, 71, 87, ${0.5 + Math.sin(time) * 0.5})`;
        context.lineWidth = 3;
        context.beginPath();
        context.arc(0, 0, s / 2, 0, Math.PI * 2);
        context.stroke();
    }



    if (cell.type === 'drill') {
        // Silver Inverted Triangle
        context.fillStyle = '#C0C0C0';
        context.shadowColor = '#FFF';
        context.shadowBlur = 10;

        context.beginPath();
        // Inverted Triangle
        context.moveTo(-s / 2, -s / 2); // Top Left
        context.lineTo(s / 2, -s / 2);  // Top Right
        context.lineTo(0, s / 2);     // Bottom Center
        context.closePath();
        context.fill();

        context.shadowBlur = 0; // Reset

        // Metallic Shine/Detail
        context.strokeStyle = '#FFFFFF';
        context.lineWidth = 2;
        context.beginPath();
        context.moveTo(-s / 4, -s / 2);
        context.lineTo(0, s / 4);
        context.stroke();
    }

    context.restore();
}

function drawPreview() {
    pCtx.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
    if (state.nextPiece) {
        const oldCellSize = cellSize;
        cellSize = 50;
        // Use 0,0 to perfectly center the block in the 50x50 canvas
        drawCell(pCtx, 0, 0, state.nextPiece);
        cellSize = oldCellSize;
    }

    // Draw Hold
    hCtx.clearRect(0, 0, holdCanvas.width, holdCanvas.height);
    if (state.holdPiece) {
        const oldCellSize = cellSize;
        cellSize = 50;
        drawCell(hCtx, 0, 0, state.holdPiece);
        if (!state.canHold) {
            hCtx.fillStyle = 'rgba(0,0,0,0.5)';
            hCtx.fillRect(0, 0, 50, 50);
        }
        cellSize = oldCellSize;
    }
}

function updateUI() {
    document.getElementById('score-display').innerText = state.score;
    document.getElementById('level-display').innerText = state.level;

    const pct = Math.min(100, (state.levelScore / state.scoreToNext) * 100);
    document.getElementById('level-bar').style.width = `${pct}%`;
    renderMetaUI();
}

/* --- Controls --- */
function setupControls() {
    // Set initial visibility based on settings - FORCE HIDE BY DEFAULT
    const mobileControls = document.querySelector('.mobile-controls');
    if (mobileControls) {
        // Always start hidden - only show if buttons mode is selected
        mobileControls.style.display = 'none';
    }

    window.addEventListener('keydown', e => {
        if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'Escape'].includes(e.code)) {
            e.preventDefault();
        }

        if (e.code === 'Escape') {
            togglePause();
            return;
        }

        if (state.paused || state.gameOver) return;
        if (e.code === 'ArrowLeft') movePiece(-1, 0);
        if (e.code === 'ArrowRight') movePiece(1, 0);
        if (e.code === 'ArrowDown') movePiece(0, 1);
        if (e.code === 'Space') {
            if (!state.spaceLocked) {
                hardDrop();
                state.spaceLocked = true;
            }
        }
        if (e.code === 'ShiftLeft' || e.code === 'ShiftRight' || e.code === 'KeyC') holdPiece();
    });

    window.addEventListener('keyup', e => {
        if (e.code === 'Space') {
            state.spaceLocked = false;
        }
    });

    // --- Mouse Controls (PC Only) ---
    canvas.addEventListener('mousemove', e => {
        const rect = canvas.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const targetCol = Math.floor(mouseX / cellSize);

        // Always track cursor position when mouse controls enabled (for spawn)
        if (state.settings.mouseEnabled) {
            state.lastMouseColumn = targetCol;
        }

        // Move active piece to cursor column
        if (state.settings.mouseEnabled && !state.paused && !state.gameOver && state.activePiece) {
            if (targetCol >= 0 && targetCol < CONFIG.cols) {
                const currentCol = state.activePiece.x;
                const deltaX = targetCol - currentCol;

                // Move piece to target column
                if (deltaX !== 0) {
                    const direction = deltaX > 0 ? 1 : -1;
                    const steps = Math.abs(deltaX);
                    for (let i = 0; i < steps; i++) {
                        movePiece(direction, 0);
                    }
                }
            }
        }
    });

    canvas.addEventListener('click', e => {
        if (!state.settings.mouseEnabled || state.paused || state.gameOver) return;
        e.preventDefault();
        hardDrop();
    });

    canvas.addEventListener('contextmenu', e => {
        if (!state.settings.mouseEnabled || state.paused || state.gameOver) return;
        e.preventDefault();
        holdPiece();
    });

    // Scroll wheel to move down
    canvas.addEventListener('wheel', e => {
        if (!state.settings.mouseEnabled || state.paused || state.gameOver) return;
        e.preventDefault();
        if (e.deltaY > 0) { // Scrolling down
            movePiece(0, 1);
        }
    }, { passive: false });

    const startBtn = document.getElementById('start-btn');
    if (startBtn) startBtn.addEventListener('click', startGame);

    const bind = (id, fn) => {
        const el = document.getElementById(id);
        if (el) {
            el.addEventListener('mousedown', (e) => { e.preventDefault(); fn(); });
            el.addEventListener('touchstart', (e) => { e.preventDefault(); fn(); });
        }
    };

    bind('btn-left', () => movePiece(-1, 0));
    bind('btn-right', () => movePiece(1, 0));
    bind('btn-down', () => movePiece(0, 1));
    bind('btn-hard-drop', () => hardDrop());

    // Hold panel - tap to hold
    const holdPanel = document.getElementById('hold-panel');
    if (holdPanel) {
        holdPanel.addEventListener('mousedown', (e) => { e.preventDefault(); e.stopPropagation(); holdPiece(); });
        holdPanel.addEventListener('touchstart', (e) => { e.preventDefault(); e.stopPropagation(); holdPiece(); });
    }

    // Update Hold Hint based on device
    const holdHint = document.getElementById('hold-hint');
    if (holdHint) {
        if (window.innerWidth < 768) {
            holdHint.innerText = "(Tap)";
        } else {
            holdHint.innerText = "(Shift/C)";
        }
    }

    // --- Swipe Controls with Tap-to-Drop ---
    const touchZone = document.getElementById('app-root');

    touchZone.addEventListener('touchstart', e => {
        if (state.settings.controlScheme !== 'swipe' || state.paused || state.gameOver) return;

        // Ignore touches on hold panel
        if (e.target.closest('#hold-panel')) return;

        const touch = e.touches[0];
        state.touchStartX = touch.clientX;
        state.touchStartY = touch.clientY;
        state.touchLastX = touch.clientX;
        state.touchLastY = touch.clientY;
        state.touchStartTime = Date.now();
        state.isDragging = false;
    }, { passive: false });

    touchZone.addEventListener('touchmove', e => {
        if (state.settings.controlScheme !== 'swipe' || state.paused || state.gameOver) return;
        if (e.cancelable) e.preventDefault();

        const touch = e.touches[0];
        const dx = touch.clientX - state.touchLastX;
        const dy = touch.clientY - state.touchLastY;

        if (Math.abs(dx) > 20) {
            const steps = Math.floor(Math.abs(dx) / 20);
            const dir = dx > 0 ? 1 : -1;
            for (let i = 0; i < steps; i++) movePiece(dir, 0);
            state.touchLastX = touch.clientX;
            state.isDragging = true;
        }

        if (dy > 30) {
            movePiece(0, 1);
            state.touchLastY = touch.clientY;
            state.isDragging = true;
        }
    }, { passive: false });

    touchZone.addEventListener('touchend', e => {
        if (state.settings.controlScheme !== 'swipe' || state.paused || state.gameOver) return;

        const duration = Date.now() - state.touchStartTime;
        const dist = Math.hypot(state.touchLastX - state.touchStartX, state.touchLastY - state.touchStartY);

        // Tap Detection
        if (duration < state.tapThreshold && dist < state.dragThreshold) {
            const canvas = document.getElementById('game-canvas');
            const rect = canvas.getBoundingClientRect();
            const tapX = state.touchStartX;
            const tapY = state.touchStartY;

            // If tapping on the game board - position AND drop
            if (tapX >= rect.left && tapX <= rect.right && tapY >= rect.top && tapY <= rect.bottom) {
                const relativeX = tapX - rect.left;
                const targetCol = Math.floor(relativeX / cellSize);

                if (state.activePiece && targetCol >= 0 && targetCol < CONFIG.cols) {
                    const currentCol = state.activePiece.x;
                    const diff = targetCol - currentCol;

                    // Move to column
                    if (diff !== 0) {
                        const dir = diff > 0 ? 1 : -1;
                        for (let i = 0; i < Math.abs(diff); i++) {
                            if (!movePiece(dir, 0)) break;
                        }
                    }

                    // Then instantly drop!
                    setTimeout(() => hardDrop(), 50);
                }
            } else {
                // Tap outside = just hard drop
                hardDrop();
            }
        }
    });
}

// Gemini Logo Flip Animation
const geminiLogo = document.querySelector('.footer img');
if (geminiLogo) {
    geminiLogo.addEventListener('click', () => {
        geminiLogo.classList.add('flip');
        setTimeout(() => {
            geminiLogo.classList.remove('flip');
        }, 600);
    });
}

// Init
init();
