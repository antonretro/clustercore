(function attachClusterCoreMatchEngine(global) {
    function checkCells(c1, c2, axis) {
        if (!c1 || !c2) return false;
        if (c1.type === 'bomb' || c2.type === 'bomb') return false;
        if (c1.type === 'dead' || c2.type === 'dead') return false;
        if (c1.id !== c2.id) return false;

        if (c1.type === 'metal') {
            if (axis === 'h' && c1.dir !== 0) return false;
            if (axis === 'v' && c1.dir !== 1) return false;
            if (axis === 'd') return false;
        }
        if (c2.type === 'metal') {
            if (axis === 'h' && c2.dir !== 0) return false;
            if (axis === 'v' && c2.dir !== 1) return false;
            if (axis === 'd') return false;
        }
        return true;
    }

    function getNeighbors(grid, cols, totalRows, x, y, currentCell) {
        const neighbors = [];
        const dirs = [[0, 1], [0, -1], [1, 0], [-1, 0]];

        for (const [dx, dy] of dirs) {
            const nx = x + dx;
            const ny = y + dy;
            if (nx < 0 || nx >= cols || ny < 0 || ny >= totalRows) continue;

            const neighbor = grid[ny][nx];
            let axis = 'n';
            if (dx !== 0) axis = 'h';
            if (dy !== 0) axis = 'v';

            if (checkCells(currentCell, neighbor, axis)) {
                neighbors.push({ x: nx, y: ny });
            }
        }

        return neighbors;
    }

    function collectCluster(grid, cols, totalRows, startX, startY, visited, getKey) {
        const cluster = [];
        const queue = [{ x: startX, y: startY }];
        let head = 0;

        const startKey = getKey(startX, startY);
        visited.add(startKey);
        cluster.push({ x: startX, y: startY });

        while (head < queue.length) {
            const current = queue[head++];
            const currentCell = grid[current.y][current.x];
            const neighbors = getNeighbors(grid, cols, totalRows, current.x, current.y, currentCell);

            for (const n of neighbors) {
                const nKey = getKey(n.x, n.y);
                if (visited.has(nKey)) continue;
                visited.add(nKey);
                cluster.push(n);
                queue.push(n);
            }
        }

        return cluster;
    }

    function addClusterMatches(grid, cols, totalRows, toClear, getKey) {
        const visited = new Set();

        for (let y = 0; y < totalRows; y++) {
            for (let x = 0; x < cols; x++) {
                const key = getKey(x, y);
                if (visited.has(key)) continue;

                const cell = grid[y][x];
                if (!cell || cell.type === 'bomb' || cell.type === 'dead') continue;

                const cluster = collectCluster(grid, cols, totalRows, x, y, visited, getKey);
                if (cluster.length < 4) continue;

                const clusterSet = new Set(cluster.map(c => getKey(c.x, c.y)));
                const badMetals = [];

                for (const c of cluster) {
                    const clusterCell = grid[c.y][c.x];
                    if (clusterCell.type !== 'metal') continue;

                    const axis = (clusterCell.dir === 0) ? 'h' : 'v';
                    let count = 1;
                    const dirs = (axis === 'h') ? [[0, -1], [0, 1]] : [[-1, 0], [1, 0]];

                    for (const [dy, dx] of dirs) {
                        let k = 1;
                        while (true) {
                            const ny = c.y + dy * k;
                            const nx = c.x + dx * k;
                            if (!clusterSet.has(getKey(nx, ny))) break;
                            count++;
                            k++;
                        }
                    }

                    if (count < 4) badMetals.push(c);
                }

                if (badMetals.length === 0) {
                    for (const c of cluster) toClear.add(getKey(c.x, c.y));
                    continue;
                }

                for (const bm of badMetals) clusterSet.delete(getKey(bm.x, bm.y));

                const remaining = Array.from(clusterSet);
                const processed = new Set();

                for (const startKey of remaining) {
                    if (processed.has(startKey)) continue;

                    const subCluster = [startKey];
                    const subQueue = [startKey];
                    let subHead = 0;
                    processed.add(startKey);

                    while (subHead < subQueue.length) {
                        const currentKey = subQueue[subHead++];
                        const [cy, cx] = currentKey.split(',').map(Number);
                        const currentCell = grid[cy][cx];

                        for (const [dx, dy] of [[0, 1], [0, -1], [1, 0], [-1, 0]]) {
                            const ny = cy + dy;
                            const nx = cx + dx;
                            const neighborKey = getKey(nx, ny);
                            if (!clusterSet.has(neighborKey) || processed.has(neighborKey)) continue;

                            const neighbor = grid[ny][nx];
                            let axis = 'n';
                            if (dx !== 0) axis = 'h';
                            if (dy !== 0) axis = 'v';

                            if (!checkCells(currentCell, neighbor, axis)) continue;

                            processed.add(neighborKey);
                            subQueue.push(neighborKey);
                            subCluster.push(neighborKey);
                        }
                    }

                    if (subCluster.length >= 4) {
                        for (const key of subCluster) toClear.add(key);
                    }
                }
            }
        }
    }

    function addDiagonalMatches(grid, cols, totalRows, toClear, getKey) {
        // Diagonal (Top-Left to Bottom-Right)
        for (let y = 0; y < totalRows - 3; y++) {
            for (let x = 0; x < cols - 3; x++) {
                let match = true;
                const first = grid[y][x];
                if (!first || first.type === 'bomb' || first.type === 'dead') continue;

                for (let k = 1; k < 4; k++) {
                    const next = grid[y + k][x + k];
                    if (!checkCells(first, next, 'd')) {
                        match = false;
                        break;
                    }
                }

                if (match) {
                    for (let k = 0; k < 4; k++) toClear.add(getKey(x + k, y + k));
                }
            }
        }

        // Diagonal (Bottom-Left to Top-Right)
        for (let y = 3; y < totalRows; y++) {
            for (let x = 0; x < cols - 3; x++) {
                let match = true;
                const first = grid[y][x];
                if (!first || first.type === 'bomb' || first.type === 'dead') continue;

                for (let k = 1; k < 4; k++) {
                    const next = grid[y - k][x + k];
                    if (!checkCells(first, next, 'd')) {
                        match = false;
                        break;
                    }
                }

                if (match) {
                    for (let k = 0; k < 4; k++) toClear.add(getKey(x + k, y - k));
                }
            }
        }
    }

    function expandCoreSet(grid, cols, totalRows, toClear, getKey) {
        let expanding = true;
        while (expanding) {
            expanding = false;
            const currentSet = Array.from(toClear);

            for (const key of currentSet) {
                const [y, x] = key.split(',').map(Number);
                const coreCell = grid[y][x];
                if (!coreCell) continue;

                for (const [dx, dy] of [[0, 1], [0, -1], [1, 0], [-1, 0]]) {
                    // Metal Source Restriction: Metal blocks only expand in their direction
                    if (coreCell.type === 'metal') {
                        if (coreCell.dir === 0 && dy !== 0) continue;
                        if (coreCell.dir === 1 && dx !== 0) continue;
                    }

                    const nx = x + dx;
                    const ny = y + dy;
                    if (nx < 0 || nx >= cols || ny < 0 || ny >= totalRows) continue;

                    const neighbor = grid[ny][nx];
                    const neighborKey = getKey(nx, ny);

                    if (!neighbor) continue;
                    if (neighbor.id !== coreCell.id) continue;
                    if (neighbor.type === 'dead' || neighbor.type === 'bomb' || neighbor.type === 'metal') continue;
                    if (toClear.has(neighborKey)) continue;

                    toClear.add(neighborKey);
                    expanding = true;
                }
            }
        }
    }

    function findMatchesInGrid(grid, config, totalRows) {
        const cols = config.cols;
        const toClear = new Set();
        const getKey = (x, y) => `${y},${x}`;

        addClusterMatches(grid, cols, totalRows, toClear, getKey);
        addDiagonalMatches(grid, cols, totalRows, toClear, getKey);
        expandCoreSet(grid, cols, totalRows, toClear, getKey);

        return Array.from(toClear).map(key => {
            const [y, x] = key.split(',').map(Number);
            return { x, y };
        });
    }

    global.ClusterCoreMatchEngine = {
        findMatchesInGrid
    };
})(window);
