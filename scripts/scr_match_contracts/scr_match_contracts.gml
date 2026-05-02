// =============================================================================
// scr_match_contracts - single source of truth for matching legality
// =============================================================================

function match_cells_share_color(_c1, _c2) {
    if (_c1 == undefined || _c2 == undefined) return false;
    
    var _id1 = variable_struct_exists(_c1, "id") ? _c1.id : 0;
    var _id2 = variable_struct_exists(_c2, "id") ? _c2.id : 0;

    if (_id1 <= 0 || _id2 <= 0) return false;

    // Wilds share color with everything except void/dead (already excluded)
    if (_id1 == 999 || _id2 == 999) return true;

    return _id1 == _id2;
}

function match_arrow_allows_axis(_cell, _axis) {
    if (_cell == undefined) return false;

    if (_cell.type != "metal") return true;

    // metal dir:
    // 0 = horizontal
    // 1 = vertical
    if (_axis == "h") return _cell.dir == 0;
    if (_axis == "v") return _cell.dir == 1;

    // Metal does not count for diagonals.
    return false;
}

function match_cell_is_excluded(_cell) {
    if (_cell == undefined) return true;

    return (
        _cell.type == "bomb" ||
        _cell.type == "dead" ||
        _cell.type == "drill" ||
        _cell.type == "void"
    );
}

function match_cells_can_link(_c1, _c2, _axis, _allowMetal = true) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (match_cell_is_excluded(_c1) || match_cell_is_excluded(_c2)) return false;

    // 1. Basic Color Match (including wildcards)
    if (!match_cells_share_color(_c1, _c2)) return false;

    // 2. Metal/Arrow Restriction
    // If we don't allow metal (like in diagonal scans or cluster matching), fail immediately
    if (!_allowMetal && (_c1.type == "metal" || _c2.type == "metal")) return false;
    if (_axis == "d" && (_c1.type == "metal" || _c2.type == "metal")) return false;

    // If we DO allow metal, both sides must allow the specific axis (H or V)
    if (_c1.type == "metal" && !match_arrow_allows_axis(_c1, _axis)) return false;
    if (_c2.type == "metal" && !match_arrow_allows_axis(_c2, _axis)) return false;

    return true;
}
