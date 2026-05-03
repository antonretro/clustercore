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

    var _isDirectional = (_cell.type == "metal") || (variable_struct_exists(_cell, "core_arrow") && _cell.core_arrow);
    if (!_isDirectional) return true;

    // metal dir:
    // 0 = horizontal
    // 1 = vertical
    // 2 = cross (ULDR)
    if (_axis == "h") return (_cell.dir == 0 || _cell.dir == 2);
    if (_axis == "v") return (_cell.dir == 1 || _cell.dir == 2);

    // Metal does not count for diagonals.
    return false;
}

function match_cell_is_excluded(_cell) {
    if (_cell == undefined) return true;

    return (
        _cell.type == "bomb" ||
        _cell.type == "dead" ||
        _cell.type == "drill" ||
        _cell.type == "void" ||
        _cell.type == "asteroid"
    );
}

function match_cells_can_link(_c1, _c2, _axis, _allowMetal = true) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (match_cell_is_excluded(_c1) || match_cell_is_excluded(_c2)) return false;

    // 1. Basic Color Match (including wildcards)
    if (!match_cells_share_color(_c1, _c2)) return false;

    // If we don't allow directional matching (like in diagonal scans or cluster matching), 
    // fail immediately if either block has an arrow
    var _c1HasArrow = (_c1.type == "metal"); // Core arrows now allowed in clusters to prevent stalemates
    var _c2HasArrow = (_c2.type == "metal");

    if (!_allowMetal && (_c1HasArrow || _c2HasArrow)) return false;
    if (_axis == "d" && (_c1HasArrow || _c2HasArrow)) return false;

    // If the cell has an arrow (Metal or Core-Arrow), it must allow the specific axis
    var _isC1Dir = (_c1.type == "metal") || (variable_struct_exists(_c1, "core_arrow") && _c1.core_arrow);
    var _isC2Dir = (_c2.type == "metal") || (variable_struct_exists(_c2, "core_arrow") && _c2.core_arrow);

    if (_isC1Dir && !match_arrow_allows_axis(_c1, _axis)) return false;
    if (_isC2Dir && !match_arrow_allows_axis(_c2, _axis)) return false;

    return true;
}
