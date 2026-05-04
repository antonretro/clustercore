// =============================================================================
// scr_easing — Easing functions for smooth UI animations
// All functions take t in [0,1] and return a value in [0,1].
// =============================================================================

function ease_linear(_t) {
    return _t;
}

// Decelerates into target — smooth stop, no overshoot
function ease_out_cubic(_t) {
    return 1 - power(1 - _t, 3);
}

// Accelerates then decelerates — smooth throughout
function ease_in_out_quart(_t) {
    return (_t < 0.5) ? 8 * _t * _t * _t * _t : 1 - power(-2 * _t + 2, 4) / 2;
}

// Overshoots slightly then settles — great for UI pop-ins
function ease_out_back(_t) {
    var _c1 = 1.70158;
    var _c3 = _c1 + 1;
    return 1 + _c3 * power(_t - 1, 3) + _c1 * power(_t - 1, 2);
}

// Springy elastic bounce at end — dramatic entrance effect
function ease_out_elastic(_t) {
    if (_t == 0) return 0;
    if (_t == 1) return 1;
    var _c4 = (2 * pi) / 3;
    return power(2, -10 * _t) * sin((_t * 10 - 0.75) * _c4) + 1;
}

// Bounces at end like a ball — good for score/reward reveals
function ease_out_bounce(_t) {
    var _n1 = 7.5625;
    var _d1 = 2.75;
    if (_t < 1 / _d1) {
        return _n1 * _t * _t;
    } else if (_t < 2 / _d1) {
        _t -= 1.5 / _d1;
        return _n1 * _t * _t + 0.75;
    } else if (_t < 2.5 / _d1) {
        _t -= 2.25 / _d1;
        return _n1 * _t * _t + 0.9375;
    } else {
        _t -= 2.625 / _d1;
        return _n1 * _t * _t + 0.984375;
    }
}
