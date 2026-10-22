#!/usr/bin/env python3
"""Icones Android StockTout : mipmaps classiques + adaptive icon.
Source : assets/icons/icon_master.png (voir gen_icons.py).
"""
import os

from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = f'{BASE}/android/app/src/main/res'

# Bleu du fond de l'icone (doit matcher le maitre au pixel pres).
BG = '#1D4ED8'

master = Image.open(f'{BASE}/assets/icons/icon_master.png').convert('RGBA')

# Icones classiques par densite.
for d, s in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
             ('xxhdpi', 144), ('xxxhdpi', 192)):
    out = f'{RES}/mipmap-{d}/ic_launcher.png'
    master.resize((s, s), Image.LANCZOS).save(out)
    print(' ', out)

# Adaptive icon : fond bleu icone + logo reduit (zone sure 60 %).
for d, s in (('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
             ('xxhdpi', 324), ('xxxhdpi', 432)):
    fg = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    inner = master.resize((int(s * 0.6), int(s * 0.6)), Image.LANCZOS)
    fg.paste(inner, ((s - inner.width) // 2, (s - inner.height) // 2), inner)
    out = f'{RES}/mipmap-{d}/ic_launcher_foreground.png'
    fg.save(out)
    print(' ', out)

os.makedirs(f'{RES}/mipmap-anydpi-v26', exist_ok=True)
with open(f'{RES}/mipmap-anydpi-v26/ic_launcher.xml', 'w') as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')

with open(f'{RES}/values/ic_launcher_background.xml', 'w') as f:
    f.write(f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{BG}</color>
</resources>
''')
print('OK icones Android')
