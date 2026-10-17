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
| windows-x64 | windows-latest | ZIP avec `stockpro.exe` |
| windows-arm64 | windows-11-arm | ZIP avec `stockpro.exe` |
| macos-x64 | macos-13 (Intel) | ZIP avec `StockPro.app` |
| macos-arm64 | macos-14 (Silicon) | ZIP avec `StockPro.app` |
| linux-x64 | ubuntu-22.04 | tar.gz du bundle |

Pas de job `linux-arm64` : Flutter ne publie officiellement que des SDK
Linux x64 (verifie sur les manifests de release, methode `dart_sdk_arch`).
Le jour ou un SDK Linux ARM64 sort, dupliquer le job `linux-x64` avec
`runs-on: ubuntu-22.04-arm`.

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
