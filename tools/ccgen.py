"""Puzzle candidate generator for Cluster Core v2.

Makes random settled boards for a recipe, solves them with ccsim, and prints the
tightest ones (every piece needed, very few winning lines) as levels.txt blocks.

    python tools/ccgen.py <recipe> [count] [seed]
"""
import sys, random
sys.path.insert(0, __file__.rsplit("\\", 1)[0].rsplit("/", 1)[0])
import ccsim as S

RECIPES = {
    # name: n, colours, blocks, stones, cages, arrows, core layers, queue, specials, radius
    "basic":   dict(n=7, cols=3, blocks=(8, 12), stones=0, cages=0, arrows=0, layers=(1, 2), q=(3, 4), sp=""),
    "chain":   dict(n=7, cols=3, blocks=(10, 14), stones=0, cages=0, arrows=0, layers=(2, 2), q=(2, 3), sp=""),
    "stones":  dict(n=7, cols=3, blocks=(8, 12), stones=(2, 4), cages=0, arrows=0, layers=(1, 2), q=(3, 4), sp=""),
    "cages":   dict(n=7, cols=3, blocks=(8, 12), stones=(0, 1), cages=(2, 4), arrows=0, layers=(1, 2), q=(3, 4), sp=""),
    "arrows":  dict(n=7, cols=3, blocks=(8, 12), stones=0, cages=0, arrows=(2, 4), layers=(1, 2), q=(3, 4), sp=""),
    "tools":   dict(n=7, cols=3, blocks=(10, 14), stones=(2, 5), cages=(0, 2), arrows=0, layers=(1, 2), q=(3, 4), sp="!^?"),
    "big":     dict(n=9, cols=4, blocks=(16, 22), stones=(1, 3), cages=(1, 3), arrows=(1, 2), layers=(2, 3), q=(4, 5), sp="!^?"),
}


def rng_range(r, v):
    return r.randint(*v) if isinstance(v, tuple) else v


def build(r, rc):
    n = rc["n"]; c = n // 2
    cols = r.sample(range(6), rc["cols"])
    g = [[None] * n for _ in range(n)]
    g[c][c] = ("k", -1, 0, 0)
    layers = [r.choice(cols) for _ in range(rng_range(r, rc["layers"]))]
    st = S.State(n, g, layers, [])
    rad = c - 1

    def empty_cells(maxd):
        return [(x, y) for y in range(n) for x in range(n)
                if g[y][x] is None and max(abs(x - c), abs(y - c)) <= maxd]

    # cages sit still, place them first near the core
    for _ in range(rng_range(r, rc["cages"])):
        x, y = r.choice(empty_cells(2))
        g[y][x] = ("n", r.choice(cols), 0, 1)
    todo = (["s"] * rng_range(r, rc["stones"]) + ["a"] * rng_range(r, rc["arrows"])
            + ["n"] * rng_range(r, rc["blocks"]))
    r.shuffle(todo)
    for t in todo:
        for _try in range(12):
            cells = empty_cells(rad)
            if not cells: return None
            x, y = r.choice(cells)
            if t == "s": cell = ("s", -1, 0, 0)
            elif t == "a": cell = ("a", r.choice(cols), r.randint(0, 1), 0)
            else: cell = ("n", r.choice(cols), 0, 0)
            g[y][x] = cell
            while S.gravity_sweep(st): pass
            if not S.find_clears(st): break
            # undo: remove whatever we just placed (it may have moved) by rebuilding is costly;
            # simply recolour the newest matching cells
            for (mx, my) in S.find_clears(st):
                pass
            # remove one marked non-cage cell at random to break the match
            m = [p for p in S.find_clears(st) if not g[p[1]][p[0]][3]]
            if not m: return None
            mx, my = r.choice(m); g[my][mx] = None
            while S.gravity_sweep(st): pass
    if S.find_clears(st): return None
    sp = rc["sp"]
    ql = rng_range(r, rc["q"])
    queue = []
    for _ in range(ql):
        if sp and r.random() < 0.25:
            queue.append({"!": "B", "^": "D", "?": "P"}[r.choice(sp)])
        else:
            queue.append(r.choice(cols))
    st.queue = queue
    return st


def to_text(st, name):
    q = " ".join({"B": "!", "D": "^", "P": "?"}.get(p, S.COLORS[p] if isinstance(p, int) else p) for p in st.queue)
    lines = [f"@ {name}", "world ?", "core " + " ".join(S.COLORS[c] for c in st.seq), "queue " + q, "grid"]
    lines += [" ".join(S.cell_str(c) for c in row) for row in st.g]
    lines.append("end")
    return "\n".join(lines)


def main():
    name = sys.argv[1]
    count = int(sys.argv[2]) if len(sys.argv) > 2 else 300
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    rc = RECIPES[name]
    r = random.Random(seed)
    found = []
    for i in range(count):
        st = build(r, rc)
        if st is None: continue
        par, sol, nw, tot = S.solve(st, 150000)
        if par is None or par < len(st.queue): continue      # every piece must matter
        wins, explored = S.count_wins(st, 80000)
        # how often a sequence of moves wins at all: smaller = harder
        found.append((wins, -sum(1 for row in st.g for c in row if c), i, st, sol))
    found.sort(key=lambda f: (f[0], f[1]))
    for wins, neg, i, st, sol in found[:6]:
        print(f"// cand {name}#{seed}-{i}: allwins={wins} sol={' '.join(sol)}")
        print(to_text(st, f"{name} {seed}-{i}"))
        print()
    print(f"// {len(found)} usable of {count}", file=sys.stderr)


if __name__ == "__main__":
    main()
