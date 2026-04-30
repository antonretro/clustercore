// =============================================================================
// scr_match_contracts - single source of truth for matching legality
// =============================================================================

function match_cells_share_color(_c1, _c2) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (!variable_struct_exists(_c1, "id")) return false;
    if (!variable_struct_exists(_c2, "id")) return false;
    if (_c1.id <= 0 || _c2.id <= 0) return false;

    return _c1.id == _c2.id;
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
        _cell.type == "drill"
    );
}

function match_cells_can_link(_c1, _c2, _axis, _allowMetal = true) {
    if (match_cell_is_excluded(_c1)) return false;
    if (match_cell_is_excluded(_c2)) return false;

    if (!match_cells_share_color(_c1, _c2)) return false;

    var _c1Metal = (_c1.type == "metal");
    var _c2Metal = (_c2.type == "metal");

    if (!_allowMetal && (_c1Metal || _c2Metal)) {
        return false;
    }

    var _coreLink = (_c1.type == "core" || _c2.type == "core");

    // Core can link through metal direction so it cannot become unfairly locked.
    // Metal still cannot enter cluster/diagonal checks when _allowMetal is false.
    if (!_coreLink) {
        if (!match_arrow_allows_axis(_c1, _axis)) return false;
        if (!match_arrow_allows_axis(_c2, _axis)) return false;
    }

    return true;
}