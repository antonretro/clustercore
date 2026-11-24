"""Cluster Core v2 - reference rules engine + puzzle solver.

Mirrors scripts/scr_cc_rules exactly. Used to design levels and to compute
par (fewest shots) and a solution for every level in datafiles/levels.txt.

    python tools/ccsim.py            # solve every level, print report
    python tools/ccsim.py --write    # also write par/sol lines back to levels.txt
    python tools/ccsim.py --show N   # print level N's board and solution steps
"""
import sys, os, collections

COLORS = "poygbr"          # pink orange yellow green blue red
LEVELS = os.environ.get("CCLEVELS") or os.path.join(os.path.dirname(__file__), "..", "datafiles", "levels.txt")


# ── cells ────────────────────────────────────────────────────────────────────
# cell = (t, c, ax, cage)   t: n normal, a arrow, s stone, w wall, k core
def parse_cell(tok):
    if tok == ".": return None
    if tok == "#": return ("w", -1, 0, 0)
    if tok == "*": return ("s", -1, 0, 0)
    if tok == "C": return ("k", -1, 0, 0)
    ch = tok[0]
    if ch.lower() in COLORS:
        c = COLORS.index(ch.lower())
        cage = 1 if ch.isupper() else 0
        if len(tok) > 1 and tok[1] in "-|":
            return ("a", c, 0 if tok[1] == "-" else 1, cage)
        return ("n", c, 0, cage)
    raise ValueError("bad cell " + tok)


def cell_str(cell):
    if cell is None: return "."
    t, c, ax, cage = cell
    if t == "w": return "#"
    if t == "s": return "*"
    if t == "k": return "C"
    s = COLORS[c].upper() if cage else COLORS[c]
    if t == "a": s += "-|"[ax]
    return s


def parse_piece(tok):
    if tok == "!": return "B"     # bomb
    if tok == "^": return "D"     # drill
    if tok == "?": return "P"     # paint
    return COLORS.index(tok)


# ── state ────────────────────────────────────────────────────────────────────
class State:
    __slots__ = ("n", "g", "seq", "hp", "queue", "hold", "shots", "won")

    def __init__(self, n, g, seq, queue):
        self.n, self.g, self.seq, self.hp = n, g, seq, 0
        self.queue, self.hold, self.shots, self.won = list(queue), None, 0, False

    def copy(self):
        s = State.__new__(State)
        s.n, s.g, s.seq, s.hp = self.n, [row[:] for row in self.g], self.seq, self.hp
        s.queue, s.hold, s.shots, s.won = list(self.queue), self.hold, self.shots, self.won
        return s

    def key(self):
        return (tuple(tuple(r) for r in self.g), self.hp, tuple(self.queue), self.hold)

    def core_color(self):
        return self.seq[self.hp] if self.hp < len(self.seq) else -1


def view_to_board(n, s, x, y):
    for _ in range(s % 4):
        x, y = n - 1 - y, x
    return x, y


def dir_for_side(s):
    dx, dy = 0, -1
    for _ in range(s % 4):
        dx, dy = -dy, dx
    return dx, dy


def movable(cell):
    return cell is not None and cell[0] in "nas" and not cell[3]


def hold(st):
    """Swap the current piece with the hold slot."""
    if st.hold is None:
        if not st.queue: return False
        st.hold = st.queue.pop(0)
    elif st.queue:
        st.queue[0], st.hold = st.hold, st.queue[0]
    else:
        st.queue.append(st.hold); st.hold = None
    return True


def can_fire(st, side, lane):
    if not st.queue or st.won: return False
    n = st.n
    ex, ey = view_to_board(n, side, lane, n - 1)
    if st.queue[0] == "D":
        return True
    return st.g[ey][ex] is None


def fire(st, side, lane, log=None):
    """Fire the current piece. Mutates st. Returns list of phase names (for tests)."""
    n, c = st.n, st.n // 2
    piece = st.queue.pop(0)
    st.shots += 1
    dx, dy = dir_for_side(side)
    x, y = view_to_board(n, side, lane, n - 1)
    phases = []
    if piece == "D":
        drilled = 0
        for k in range(n - 1, c - 1, -1):
            bx, by = view_to_board(n, side, lane, k)
            cell = st.g[by][bx]
            if cell is None: continue
            if cell[0] in "wk": break
            st.g[by][bx] = None
            drilled += 1
            if drilled >= 3: break
        phases.append("drill")
    else:
        k = n - 1
        while k > c:
            nx, ny = x + dx, y + dy
            if st.g[ny][nx] is not None: break
            x, y, k = nx, ny, k - 1
        hit = None
        if k > c:
            hit = st.g[y + dy][x + dx]
        if piece == "B":
            for yy in range(y - 1, y + 2):
                for xx in range(x - 1, x + 2):
                    if 0 <= xx < n and 0 <= yy < n:
                        cell = st.g[yy][xx]
                        if cell is not None and cell[0] not in "wk":
                            st.g[yy][xx] = None
            phases.append("bomb")
        elif piece == "P":
            if hit is not None and hit[0] in "na":
                st.g[y][x] = ("n", hit[1], 0, 0)
            elif hit is not None and hit[0] == "k" and st.core_color() >= 0:
                st.g[y][x] = ("n", st.core_color(), 0, 0)
            else:
                st.g[y][x] = ("s", -1, 0, 0)
            phases.append("land")
        else:
            st.g[y][x] = ("n", piece, 0, 0)
            phases.append("land")
    resolve(st, phases)
    return phases


def gravity_sweep(st):
    n, c = st.n, st.n // 2
    moved = False
    for (x, y) in ORDER[n]:
        cell = st.g[y][x]
        if not movable(cell): continue
        dx, dy = x - c, y - c
        if abs(dy) >= abs(dx):
            tx, ty = x, y - (1 if dy > 0 else -1)
        else:
            tx, ty = x - (1 if dx > 0 else -1), y
        if st.g[ty][tx] is None:
            st.g[ty][tx] = cell
            st.g[y][x] = None
            moved = True
    return moved


def find_clears(st):
    n = st.n
    g = st.g
    marked = set()
    seen = set()
    for y in range(n):
        for x in range(n):
            cell = g[y][x]
            if cell is None or cell[0] != "n" or (x, y) in seen: continue
            col = cell[1]
            stack, grp = [(x, y)], []
            seen.add((x, y))
            while stack:
                px, py = stack.pop()
                grp.append((px, py))
                for qx, qy in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if 0 <= qx < n and 0 <= qy < n and (qx, qy) not in seen:
                        q = g[qy][qx]
                        if q is not None and q[0] == "n" and q[1] == col:
                            seen.add((qx, qy)); stack.append((qx, qy))
            if len(grp) >= 3:
                marked.update(grp)
    for y in range(n):
        for x in range(n):
            cell = g[y][x]
            if cell is None or cell[0] != "a": continue
            ddx, ddy = (1, 0) if cell[2] == 0 else (0, 1)
            run = [(x, y)]
            for sgn in (1, -1):
                px, py = x + ddx * sgn, y + ddy * sgn
                while 0 <= px < n and 0 <= py < n:
                    q = g[py][px]
                    if q is None or q[0] not in "na" or q[1] != cell[1]: break
                    run.append((px, py)); px += ddx * sgn; py += ddy * sgn
            if len(run) >= 3:
                marked.update(run)
    return marked


def resolve(st, phases):
    n, c = st.n, st.n // 2
    while True:
        while gravity_sweep(st):
            phases.append("fall")
        marked = find_clears(st)
        if not marked:
            return
        cc = st.core_color()
        hit = False
        for (x, y) in marked:
            cell = st.g[y][x]
            if cell[3]:
                st.g[y][x] = (cell[0], cell[1], cell[2], 0)
            else:
                st.g[y][x] = None
            if abs(x - c) + abs(y - c) == 1 and cell[1] == cc:
                hit = True
        phases.append("pop")
        if hit and st.g[c][c] is not None and st.g[c][c][0] == "k":
            st.hp += 1
            phases.append("core")
            if st.hp >= len(st.seq):
                st.g[c][c] = None
                st.won = True
                phases.append("win")
                return


ORDER = {}
for _n in (5, 7, 9, 11):
    _c = _n // 2
    ORDER[_n] = sorted(((x, y) for y in range(_n) for x in range(_n)),
                       key=lambda p: (abs(p[0] - _c) + abs(p[1] - _c), p[1], p[0]))


# ── levels file ──────────────────────────────────────────────────────────────
def load_levels(path=LEVELS):
    levels, cur = [], None
    lines = open(path, encoding="utf-8").read().splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]; i += 1
        line = raw.strip()
        if not line or line.startswith("//"): continue
        if line.startswith("@"):
            cur = {"name": line[1:].strip(), "line": i - 1, "props": {}}
            levels.append(cur); continue
        if line == "grid":
            rows = []
            while lines[i].strip() != "end":
                rows.append(lines[i].split()); i += 1
            i += 1
            cur["rows"] = rows; continue
        key, _, val = line.partition(" ")
        cur["props"][key] = val.strip()
    return levels, lines


def make_state(lv):
    rows = lv["rows"]
    n = len(rows)
    assert all(len(r) == n for r in rows), lv["name"] + ": grid not square"
    g = [[parse_cell(t) for t in r] for r in rows]
    c = n // 2
    assert g[c][c] is not None and g[c][c][0] == "k", lv["name"] + ": core not in centre"
    seq = [COLORS.index(ch) for ch in lv["props"]["core"].split()]
    queue = [parse_piece(t) for t in lv["props"]["queue"].split()]
    return State(n, g, seq, queue)


# ── solver ───────────────────────────────────────────────────────────────────
def successors(st):
    """Yield (moves, state) for every distinct result of one shot (with optional hold first)."""
    seen = set()
    for pre in (False, True):
        base = st.copy()
        if pre and not hold(base): continue
        if not base.queue: continue
        for side in range(4):
            for lane in range(st.n):
                if not can_fire(base, side, lane): continue
                s2 = base.copy()
                fire(s2, side, lane)
                k = s2.key()
                if k in seen: continue
                seen.add(k)
                yield ((["H"] if pre else []) + ["%d,%d" % (side, lane)], s2)


def solve(st, max_states=400000):
    """BFS on shots. Returns (par, moves, wins_at_par, states) or (None, None, 0, states)."""
    frontier = [(st, [])]
    visited = {st.key()}
    total = 0
    while frontier:
        nxt, found = [], []
        for s, path in frontier:
            for mv, s2 in successors(s):
                total += 1
                if s2.won:
                    found.append(path + mv); continue
                k = s2.key()
                if k in visited: continue
                visited.add(k)
                if s2.queue or s2.hold is not None:
                    nxt.append((s2, path + mv))
            if total > max_states:
                return None, None, 0, total
        if found:
            return len([m for m in found[0] if m != "H"]), found[0], len(found), total
        frontier = nxt
    return None, None, 0, total


def count_wins(st, limit=200000):
    """Count distinct winning shot sequences (any length) - how 'loose' a puzzle is."""
    wins = 0; total = 0
    stack = [st]
    seen = set()
    while stack:
        s = stack.pop()
        for mv, s2 in successors(s):
            total += 1
            if total > limit: return wins, total
            if s2.won: wins += 1; continue
            k = s2.key()
            if k in seen: continue
            seen.add(k)
            if s2.queue or s2.hold is not None: stack.append(s2)
    return wins, total


def check_stable(st):
    s = st.copy()
    ph = []
    resolve(s, ph)
    return not ph


def show(st):
    print("\n".join(" ".join(f"{cell_str(c):>2}" for c in row) for row in st.g))
    print("core", st.seq[st.hp:], "queue", st.queue, "hold", st.hold)


def main():
    levels, lines = load_levels()
    args = sys.argv[1:]
    if "--show" in args:
        idx = int(args[args.index("--show") + 1])
        lv = levels[idx]; st = make_state(lv)
        show(st)
        par, sol, nw, tot = solve(st)
        print("par", par, "sol", sol)
        for m in sol or []:
            if m == "H": hold(st); print("-- hold"); continue
            s, l = map(int, m.split(","))
            print("-- fire side", s, "lane", l, fire(st, s, l)); show(st)
        return
    out = {}
    bad = 0
    for idx, lv in enumerate(levels):
        st = make_state(lv)
        if not check_stable(st):
            print(f"{idx:2} {lv['name']:<24} UNSTABLE start board"); bad += 1; continue
        par, sol, nwin, tot = solve(st)
        wins, _ = count_wins(st, 60000)
        q = len(st.queue)
        tag = "" if par else "  <-- NO SOLUTION"
        if par:
            out[idx] = (par, sol)
        else:
            bad += 1
        print(f"{idx:2} w{lv['props'].get('world','?')} {lv['name']:<24} n={st.n} queue={q:2} par={par} "
              f"parwins={nwin:3} allwins={wins:5} states={tot:6} sol={' '.join(sol or [])}{tag}")
    if "--write" in args:
        new, li = [], 0
        starts = {lv["line"]: idx for idx, lv in enumerate(levels)}
        cur = None
        for i, line in enumerate(lines):
            if i in starts: cur = starts[i]
            s = line.strip()
            if cur in out and (s.startswith("par ") or s.startswith("sol ")):
                continue
            new.append(line)
            if i in starts and cur in out:
                new.append("par " + str(out[cur][0]))
                new.append("sol " + " ".join(out[cur][1]))
        open(LEVELS, "w", encoding="utf-8", newline="\n").write("\n".join(new) + "\n")
        print("wrote", LEVELS)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
