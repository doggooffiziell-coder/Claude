# Erzeugt alle Icon-Dateien neu: python3 make_icon.py .
# Pixel-Art-Icon für Ant Pop: 48 x 48 Pixel, danach scharf vergrößert.
from PIL import Image
import sys

N = 48
img = Image.new("RGBA", (N, N))
px = img.load()

def hexc(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)

C = {k: hexc(v) for k, v in {
    "frame": "#17402a", "frame_l": "#3f7a52", "frame_d": "#0a1f12",
    "sky0": "#86bde8", "sky1": "#9ccbed", "sky2": "#b5d9f0", "sky3": "#cde6f2", "sky4": "#ddeef3",
    "sun": "#ffe98c", "sun_l": "#fff6cc", "glow": "#eef0c6",
    "cloud": "#fbfcff", "cloud_d": "#dfe8f0",
    "leaf_d": "#3d6b33", "leaf": "#548f4a", "leaf_l": "#86c06a",
    "trunk": "#734d30", "trunk_d": "#4f331f",
    "fruit": "#d4352a", "fruit_d": "#9e1f18", "fruit_l": "#ffc2b4",
    "grass": "#5f9e4c", "grass_d": "#40733a", "flower": "#f2c84b",
    "sand0": "#ddc287", "sand0d": "#c4a66c", "sand0l": "#ead3a0", "sand1": "#c9ac77", "sand1d": "#ad8f60", "line": "#8f7448",
    "tunnel": "#5c3d24", "rim": "#3a2516", "queen_ch": "#4d474d", "queen_r": "#2b272b",
    "brood": "#84618c", "brood_r": "#4e3654", "gran": "#b89e3d", "gran_r": "#6f5f26", "egg": "#fbf6e8",
    "ant": "#2a140e", "ant_m": "#4c2819", "ant_h": "#94543a", "outline": "#100604",
    "crown": "#f2c94c", "crown_l": "#fff0a8", "crown_d": "#a8811c", "gem": "#e0453a", "eye": "#f4e2c8",
    "stone": "#9a958c", "stone_l": "#c9c5bc",
}.items()}

def put(x, y, c):
    if 0 <= x < N and 0 <= y < N: px[x, y] = c

def rect(x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w): put(xx, yy, c)

def shape(test, c, thr=0.5):
    mask = set()
    for y in range(N):
        for x in range(N):
            n = sum(1 for sy in range(6) for sx in range(6) if test(x + (sx + 0.5) / 6, y + (sy + 0.5) / 6))
            if n / 36 > thr:
                put(x, y, c); mask.add((x, y))
    return mask

ell = lambda cx, cy, rx, ry: (lambda x, y: ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1)
union = lambda *fs: (lambda x, y: any(f(x, y) for f in fs))
box = lambda x0, y0, x1, y1: (lambda x, y: x0 <= x <= x1 and y0 <= y <= y1)

def line(x0, y0, x1, y1, c, mask=None):
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    e = dx + dy
    while True:
        put(x0, y0, c)
        if mask is not None: mask.add((x0, y0))
        if x0 == x1 and y0 == y1: break
        e2 = 2 * e
        if e2 >= dy: e += dy; x0 += sx
        if e2 <= dx: e += dx; y0 += sy

GROUND = 27
# Himmel in Bändern
sky = ["sky0", "sky1", "sky2", "sky3", "sky4"]
for y in range(GROUND):
    rect(0, y, N, 1, C[sky[min(4, y * 5 // GROUND)]])
# Sonne oben links
shape(ell(9.5, 8.5, 5.6, 5.6), C["glow"])
shape(ell(9.5, 8.5, 4.0, 4.0), C["sun"])
shape(ell(8.5, 7.5, 1.6, 1.6), C["sun_l"])
# Wolke
shape(union(ell(22, 8.5, 3.2, 2.4), ell(25.5, 7.2, 3.4, 3.0), ell(29, 8.8, 2.6, 2.0)), C["cloud_d"])
shape(union(ell(22, 8, 3.0, 2.1), ell(25.5, 6.8, 3.2, 2.7), ell(29, 8.3, 2.4, 1.8)), C["cloud"])
# Baum rechts
rect(40, 14, 3, 13, C["trunk"]); rect(42, 14, 1, 13, C["trunk_d"]); rect(39, 25, 5, 2, C["trunk"])
shape(union(ell(41.5, 11.5, 7.0, 6.4), ell(37.5, 14.0, 3.2, 2.8), ell(46, 13, 3.5, 3.4)), C["leaf_d"])
shape(union(ell(41, 10.8, 6.2, 5.6), ell(37.6, 13.2, 2.6, 2.2), ell(45.5, 12.2, 3.0, 2.8)), C["leaf"])
shape(union(ell(38.8, 8.4, 2.4, 1.9), ell(44, 8.2, 1.6, 1.3)), C["leaf_l"])
for fx, fy in [(37, 11), (43, 8), (41, 13), (45, 12), (38, 15)]:
    rect(fx, fy, 2, 2, C["fruit"]); put(fx + 1, fy + 1, C["fruit_d"]); put(fx, fy, C["fruit_l"])
# Boden
for y in range(GROUND, N):
    rect(0, y, N, 1, C["sand0"] if y < 38 else C["sand1"])
for x in range(0, N, 4):
    rect(x, 38, 2, 1, C["line"])
for i, (x, y) in enumerate([(3, 30), (11, 33), (30, 31), (44, 34), (6, 44), (41, 44), (17, 45), (2, 40), (35, 30)]):
    put(x, y, C["sand0d"] if y < 38 else C["sand1d"])
for x, y in [(44, 29), (4, 35)]:
    rect(x, y, 2, 1, C["stone"]); put(x, y, C["stone_l"])
# Grasnarbe mit Halmen und Blumen
rect(0, GROUND, N, 1, C["grass"])
for x in range(1, N, 2):
    if 15 <= x <= 33: continue
    put(x, GROUND - 1, C["grass"] if x % 4 == 1 else C["grass_d"])
    if x % 6 == 3: put(x, GROUND - 2, C["grass"])
for x in (5, 45):
    rect(x, GROUND - 4, 1, 3, C["grass_d"]); put(x, GROUND - 5, C["flower"]); put(x - 1, GROUND - 5, C["flower"]); put(x + 1, GROUND - 5, C["flower"]); put(x, GROUND - 6, C["flower"])
# Sandhügel am Eingang
shape(ell(24.5, GROUND + 0.6, 10.5, 3.6), C["sand0"])
shape(ell(22, GROUND - 1.6, 4.5, 1.0), C["sand0l"])
for x, y in [(18, 26), (29, 25), (31, 27)]: put(x, y, C["sand0d"])
# Tunnel und Kammern: erst der dunkle Rand, dann die Füllung
steps = [(23.4, 24.6, 26.4, 28.4), (21.4, 27.6, 24.6, 30.4), (19.6, 29.6, 22.6, 33)]
tun = union(*[box(*b) for b in steps], box(9, 37.6, 16, 40.4), box(26, 37.6, 33, 40.4))
rooms_r = union(ell(21, 34.8, 8.6, 3.6), ell(9.5, 41.6, 5.8, 3.0), ell(37.5, 41.6, 6.8, 3.0))
shape(union(tun, rooms_r, *[box(b[0] - 0.8, b[1] - 0.8, b[2] + 0.8, b[3] + 0.6) for b in steps], box(8.2, 36.8, 16.8, 41), box(25.2, 36.8, 33.8, 41)), C["rim"], 0.3)
shape(tun, C["tunnel"])
shape(ell(21, 34.8, 7.6, 2.7), C["queen_ch"])
shape(ell(9.5, 41.6, 4.8, 2.2), C["brood"])
shape(ell(37.5, 41.6, 5.8, 2.2), C["gran"])
for x, y in [(34, 42), (36, 42), (38, 42), (40, 42), (35, 41), (37, 41), (39, 41)]:
    put(x, y, C["fruit"] if (x + y) % 2 else C["crown"])
for x, y in [(7, 42), (9, 42), (11, 41), (12, 42)]: put(x, y, C["egg"])
# kleine Arbeiterinnen im Nest
for (x, y, d) in [(21, 31, 1), (15, 35, 0), (28, 39, 1)]:
    put(x, y, C["ant"]); put(x + 1, y, C["ant"]); put(x + 2 if d == 0 else x - 1, y, C["ant"])
    put(x, y + 1, C["ant_m"]); put(x + 2, y + 1, C["ant_m"])
# Krümel im Tunnel
put(15, 39, C["rim"]); put(30, 38, C["rim"])

# Königin auf dem Hügel: Seitenansicht, Blick nach rechts
ant = set()
ant |= shape(union(ell(13.0, 18.0, 6.2, 4.2), ell(19.9, 19.0, 1.1, 1.0), ell(23.4, 18.2, 2.7, 1.9), ell(28.8, 15.8, 3.1, 2.9)), C["ant"])
for p in [(32, 17), (33, 17), (33, 18)]: put(*p, C["ant"]); ant.add(p)
crown = [(26, 10), (28, 9), (30, 10), (26, 11), (27, 11), (28, 11), (29, 11), (30, 11), (26, 12), (27, 12), (28, 12), (29, 12), (30, 12)]
for p in crown: ant.add(p)
# Kontur nur um Körper und Krone
outline = set()
for (x, y) in ant:
    for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
        q = (x + dx, y + dy)
        if q not in ant: outline.add(q)
for q in outline: put(*q, C["outline"])
# Beine der hinteren Seite etwas heller, dann die vordere Seite
for (a, b, c2) in [((22, 20), (20, 23), (19, 25)), ((25, 20), (26, 23), (25, 25))]:
    line(*a, *b, C["ant_m"]); line(*b, *c2, C["ant_m"])
for (a, b, c2) in [((21, 21), (17, 22), (15, 25)), ((23, 21), (23, 23), (22, 25)), ((25, 21), (28, 22), (30, 25))]:
    line(*a, *b, C["ant"]); line(*b, *c2, C["ant"])
# Fühler
line(30, 13, 32, 10, C["ant"]); line(32, 10, 35, 9, C["ant"]); put(36, 10, C["ant"])
# Segmente, Glanz und Auge
for x in (11, 15):
    for y in range(14, 23):
        if ell(13.0, 18.0, 5.4, 3.4)(x + 0.5, y + 0.5): put(x, y, C["ant_m"])
for p in [(9, 15), (10, 15), (8, 16), (11, 14), (12, 14), (22, 17), (23, 17), (27, 14), (28, 14)]: put(*p, C["ant_h"])
put(30, 15, C["eye"])
# Krone mit Edelstein
for p in crown: put(*p, C["crown"])
put(28, 11, C["gem"]); put(26, 11, C["crown_l"]); put(28, 9, C["crown_l"]); put(30, 12, C["crown_d"]); put(29, 12, C["crown_d"])

# Rahmen wie das Formicarium
rect(0, 0, N, 2, C["frame"]); rect(0, N - 2, N, 2, C["frame"]); rect(0, 0, 2, N, C["frame"]); rect(N - 2, 0, 2, N, C["frame"])
rect(2, 2, N - 4, 1, C["frame_d"]) if False else None

out = sys.argv[1]
img.save(f"{out}/icon_48.png")
for s in [16, 32, 64, 128, 180, 192, 256, 512, 1024]:
    k = max(1, -(-s // N))
    big = img.resize((N * k, N * k), Image.NEAREST)
    if big.size[0] != s: big = big.resize((s, s), Image.NEAREST)
    big.save(f"{out}/icon_{s}.png")
fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
fg.paste(img.resize((288, 288), Image.NEAREST), (72, 72))
fg.save(f"{out}/icon_android_foreground_432.png")
Image.new("RGBA", (432, 432), C["frame"]).save(f"{out}/icon_android_background_432.png")
rects = []
for y in range(N):
    x = 0
    while x < N:
        c = px[x, y]; x0 = x
        while x < N and px[x, y] == c: x += 1
        rects.append(f'<rect x="{x0}" y="{y}" width="{x - x0}" height="1" fill="#{c[0]:02x}{c[1]:02x}{c[2]:02x}"/>')
open(f"{out}/icon.svg", "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 {N} {N}" shape-rendering="crispEdges">' + "".join(rects) + "</svg>\n")
print("ok")
