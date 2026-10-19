#!/usr/bin/env python3
"""Genere le logo StockTout + toutes les icones (Windows .ico, macOS, in-app).

Logo : blason bleu profond, cartons blancs empiles, accent ambre.
Source de verite : ce script. Relancer apres modif, commiter les PNG.
"""
import json
import os

from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 2  # sur-echantillonnage anti-aliasing
S = 1024 * SS

NAVY_TOP = (34, 99, 184)
NAVY_BOT = (19, 56, 110)
WHITE = (255, 255, 255)
WHITE_DIM = (242, 246, 252)
TAPE = (215, 227, 244)
AMBER = (245, 166, 35)
AMBER_DARK = (217, 138, 18)
STROKE = (14, 42, 82)


def rounded(draw, box, radius, fill=None, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius * SS, fill=fill,
                           outline=outline, width=width * SS)


def box(draw, x, y, w, h, r, fill, tape, tape_w=40):
    st = 6
    # ombre
    rounded(draw, [x, y + 16, x + w, y + h + 16], r, fill=(0, 0, 0, 60))
    # corps
    rounded(draw, [x, y, x + w, y + h], r, fill=fill,
            outline=STROKE, width=st)
    # scotch vertical
    cx = x + w // 2
    draw.rectangle([cx - tape_w // 2, y + st, cx + tape_w // 2, y + h - st],
                   fill=tape)


def render(size=1024):
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, 'RGBA')
    # fond : degrade vertical dans un blason arrondi
    radius = 230 * SS
    for yy in range(S):
        t = yy / S
        c = tuple(int(NAVY_TOP[i] + (NAVY_BOT[i] - NAVY_TOP[i]) * t)
                  for i in range(3))
        d.line([(0, yy), (S, yy)], fill=c)
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=radius,
                                           fill=255)
    bg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    bg.paste(Image.new('RGBA', (S, S), NAVY_TOP + (255,)), (0, 0))
    # degrade reel
    grad = Image.new('RGBA', (S, S))
    gd = ImageDraw.Draw(grad)
    for yy in range(S):
        t = yy / S
        c = tuple(int(NAVY_TOP[i] + (NAVY_BOT[i] - NAVY_TOP[i]) * t)
                  for i in range(3)) + (255,)
        gd.line([(0, yy), (S, yy)], fill=c)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img, 'RGBA')

    u = SS  # unite = px@1024 * SS
    # cartons empiles (coordonnees en px@1024)
    box(d, 232 * u, 620 * u, 560 * u, 200 * u, 28, WHITE, TAPE)
    box(d, 272 * u, 448 * u, 480 * u, 180 * u, 26, WHITE_DIM, TAPE)
    box(d, 392 * u, 268 * u, 240 * u, 180 * u, 24, AMBER, AMBER_DARK)
    # reflet haut du cube ambre
    d.rounded_rectangle([412 * u, 288 * u, 492 * u, 316 * u],
                        radius=14 * u, fill=(255, 255, 255, 110))
    return img.resize((size, size), Image.LANCZOS)


def save_png(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(' ', path)


def main():
    master = render(1024)
    save_png(master, f'{BASE}/assets/icons/logo_master_1024.png')
    save_png(render(512), f'{BASE}/assets/images/logo.png')
    for s in (16, 32, 48, 64, 128, 256, 512, 1024):
        save_png(render(s), f'{BASE}/assets/icons/png/appicon_{s}.png')

    # Windows .ico multi-tailles
    ico_path = f'{BASE}/windows/runner/resources/app_icon.ico'
    master.save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48),
                                 (64, 64), (128, 128), (256, 256)])
    print(' ', ico_path)

    # macOS : memes noms que le Contents.json du template
    aset = f'{BASE}/macos/Runner/Assets.xcassets/AppIcon.appiconset'
    names = json.load(open(f'{aset}/Contents.json'))['images']
    done = set()
    for entry in names:
        fn = entry.get('filename')
        if not fn or fn in done:
            continue
        done.add(fn)
        size = int(float(entry['size'].split('x')[0]) *
                   int(entry['scale'][0]))
        render(size).save(f'{aset}/{fn}')
        print(' ', f'{aset}/{fn}')
    print('OK')


if __name__ == '__main__':
    main()
