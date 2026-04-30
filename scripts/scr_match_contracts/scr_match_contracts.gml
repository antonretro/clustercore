// =============================================================================
// scr_match_contracts - single source of truth for matching legality
// =============================================================================

function match_cells_share_color(_c1, _c2) {
    if (_c1 == undefined || _c2 == undefined) return false;
    return _c1.id == _c2.id;
}

function match_arrow_allows_axis(_cell, _axis) {
    if (_cell == undefined) return false;
    if (_cell.type != "metal") return true;
    if (_axis == "h") return _cell.dir == 0;
    if (_axis == "v") return _cell.dir == 1;
    return false;
}

function match_cell_is_excluded(_cell) {
    if (_cell == undefined) return true;
    return (_cell.type == "bomb" || _cell.type == "dead");
}

function match_cells_can_link(_c1, _c2, _axis, _allowMetal = true) {
    if (match_cell_is_excluded(_c1) || match_cell_is_excluded(_c2)) return false;
    if (!match_cells_share_color(_c1, _c2)) return false;
    // Core is always linkable by axis, even with arrow blocks,
    // so the objective can never become unfairly blocked.
    var _coreBypass = (_c1.type == "core" || _c2.type == "core");
    if (!_coreBypass) {
        if (!match_arrow_allows_axis(_c1, _axis)) return false;
        if (!match_arrow_allows_axis(_c2, _axis)) return false;
    }
    if (!_allowMetal && (_c1.type == "metal" || _c2.type == "metal")) return false;
    return true;
}
