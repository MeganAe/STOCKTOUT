#!/usr/bin/env python3
"""Regenere le logo StockTout + toutes les icones (Windows .ico, macOS, in-app).

Source de verite : assets/icons/icon_master.png (icone creee par l'auteur).
Relancer apres remplacement du maitre, commiter les PNG generes.
"""
import json
import os

from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MASTER = f'{BASE}/assets/icons/icon_master.png'


def render(size):
    master = Image.open(MASTER).convert('RGBA')
    return master.resize((size, size), Image.LANCZOS)


def save_png(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(' ', path)


def main():
    for s in (16, 32, 48, 64, 128, 256, 512, 1024):
        save_png(render(s), f'{BASE}/assets/icons/png/appicon_{s}.png')
    # In-app (A propos, tutoriel) : 512 px.
    save_png(render(512), f'{BASE}/assets/images/logo.png')

    # Windows .ico multi-tailles
    ico_path = f'{BASE}/windows/runner/resources/app_icon.ico'
    render(256).save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48),
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
