# Compilation & releases

Tout est automatise via GitHub Actions. Le workflow est **manuel** : rien ne se
compile tout seul, c'est vous qui decidez quand sortir une version.

## 1. Mettre le projet sur GitHub

```bash
cd stockpro
git init
git add .
git commit -m "StockPro 1.0.0"
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/stockpro.git
git push -u origin main
```

## 2. Premiere release

1. Ouvrez le depot sur GitHub.
2. Onglet **Actions** > **Release** > **Run workflow** (bouton a droite).
3. Remplissez :
   - `version` : ex `1.0.0` (vide = version de `pubspec.yaml`).
   - `platforms` : `all` pour tout compiler, ou une seule plateforme.
   - `draft` : laissez `true` pour relire avant publication.
4. Lancez. Duree : ~15-30 min pour les 6 builds.
5. Quand c'est vert, allez dans **Releases** : le brouillon contient les 6 fichiers.
6. Relisez les notes, cliquez **Publish release**.

## 3. Ce qui est compile

| Job | Runner | Sortie |
|---|---|---|
| windows-x64 | windows-2022 (epingle : VS2022) | ZIP avec `stockpro.exe` |
| macos-x64 | macos-15-intel | ZIP avec `StockPro.app` |
| macos-arm64 | macos-15 | ZIP avec `StockPro.app` |
| linux-x64 | ubuntu-22.04 | tar.gz du bundle |

Runners epingles volontairement, pas de `-latest` :
- `windows-2022` : `windows-latest` est passe a VS2026, que Flutter 3.24
  ne detecte pas (`could not find any instance of Visual Studio`).
- `macos-15-intel` : `macos-13` est retire par GitHub. Dernier runner
  Intel, dispo jusqu'aout 2027.
- `macos-15` : `macos-14` est retire le 2 nov. 2026.

Pas de job `windows-arm64` : le runner `windows-11-arm` n'a que VS2026.
Pas de job `linux-arm64` : Flutter ne publie que des SDK Linux x64.
Les deux seront re-essayes apres montee de version Flutter.

## 4. Installer

**Windows** : decompressez le ZIP, double-cliquez `stockpro.exe`.
Si SmartScreen bloque : clic droit > Proprietes > debloquer, ou signez le binaire
(voir section signature).

**macOS** : decompressez, glissez `StockPro.app` dans Applications.
Premier lancement : clic droit > Ouvrir > Ouvrir (bypass Gatekeeper pour les
apps non signees).

**Linux** :
```bash
tar -xzf stockpro-linux-x64-1.0.0.tar.gz
./stockpro/stockpro
```
Note : installez `zenity` pour les dialogues de fichiers
(`sudo apt install zenity` sur Ubuntu/Debian).

## 5. Versions suivantes

```bash
# changer la version dans pubspec.yaml, ex 1.1.0+2
python3 scripts/bump_version.py 1.1.0
git add -A && git commit -m "1.1.0" && git push
# puis relancer le workflow Release avec version = 1.1.0
```

## 6. Signature (optionnel, conseille)

- **Windows** : certificat Authenticode + `signtool`. Sans signature,
  SmartScreen affiche un avertissement, l'app reste utilisable.
- **macOS** : compte Apple Developer (99 $/an), `codesign` + `notarytool`.
  Sans signature, l'ouverture par clic droit reste possible.
- **Linux** : pas de signature requise. Un `.deb` peut etre ajoute plus tard
  (voir `scripts/`).

## 7. CI (auto)

Le workflow `CI` tourne a chaque push : format, analyse, tests.
Il ne publie rien, il verifie juste que le code est sain.
