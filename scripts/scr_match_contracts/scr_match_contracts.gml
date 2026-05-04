// =============================================================================
// scr_match_contracts - single source of truth for matching legality
// =============================================================================

// WILDCARD_ID is defined in scr_match_engine — use that macro everywhere

function match_cell_id(_cell) {
    if (_cell == undefined) return 0;
    if (!variable_struct_exists(_cell, "id")) return 0;
    return _cell.id;
}

function match_cell_type(_cell) {
    if (_cell == undefined) return "";
    if (!variable_struct_exists(_cell, "type")) return "";
    return _cell.type;
}

function match_cell_is_excluded(_cell) {
    if (_cell == undefined) return true;

    var _type = match_cell_type(_cell);

    return (
        _type == "bomb" ||
        _type == "dead" ||
        _type == "drill" ||
        _type == "void" ||
        _type == "asteroid"
    );
}

function match_cell_is_wild(_cell) {
    return match_cell_id(_cell) == WILDCARD_ID;
}

function match_cell_is_metal_arrow(_cell) {
    return match_cell_type(_cell) == "metal";
}

function match_cell_is_core_arrow(_cell) {
    return (
        _cell != undefined &&
        variable_struct_exists(_cell, "core_arrow") &&
        _cell.core_arrow
    );
}

function match_cell_is_directional(_cell) {
    return match_cell_is_metal_arrow(_cell) || match_cell_is_core_arrow(_cell);
}

// This is the important split.
// Metal arrows are special line-only blocks.
// Core arrows are allowed in blobs so the core does not create stalemates.
function match_cell_blocks_blob_matching(_cell) {
    return match_cell_is_metal_arrow(_cell);
}

function match_cells_share_color(_c1, _c2) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (match_cell_is_excluded(_c1) || match_cell_is_excluded(_c2)) return false;

    var _id1 = match_cell_id(_c1);
    var _id2 = match_cell_id(_c2);

    if (_id1 <= 0 || _id2 <= 0) return false;

    if (_id1 == WILDCARD_ID || _id2 == WILDCARD_ID) return true;

    return _id1 == _id2;
}

function match_arrow_allows_axis(_cell, _axis) {
    if (_cell == undefined) return false;

    if (!match_cell_is_directional(_cell)) return true;

    // dir:
    // 0 = horizontal
    // 1 = vertical
    // 2 = cross
    var _dir = variable_struct_exists(_cell, "dir") ? _cell.dir : 2;

    if (_axis == "h") return (_dir == 0 || _dir == 2);
    if (_axis == "v") return (_dir == 1 || _dir == 2);

    // Directional blocks do not count for diagonals.
    return false;
}

function match_cells_can_link(_c1, _c2, _axis, _mode) {
    if (_c1 == undefined || _c2 == undefined) return false;
    if (match_cell_is_excluded(_c1) || match_cell_is_excluded(_c2)) return false;
    if (!match_cells_share_color(_c1, _c2)) return false;

    // _mode should be:
    // "blob"     = any connected normal-block shape
    // "line"     = horizontal/vertical line
    // "diagonal" = diagonal line

    if (_mode == "blob") {
        if (match_cell_blocks_blob_matching(_c1)) return false;
        if (match_cell_blocks_blob_matching(_c2)) return false;

        // Core arrows are allowed in blobs.
        // Metal arrows are not.
        return true;
    }

    if (_mode == "line") {
        if (match_cell_is_directional(_c1) && !match_arrow_allows_axis(_c1, _axis)) return false;
        if (match_cell_is_directional(_c2) && !match_arrow_allows_axis(_c2, _axis)) return false;
        return true;
    }

    if (_mode == "diagonal") {
        if (match_cell_is_directional(_c1)) return false;
        if (match_cell_is_directional(_c2)) return false;
        return true;
    }

    return false;
}