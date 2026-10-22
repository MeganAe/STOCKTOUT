# Compilation & releases

Tout est automatise via GitHub Actions. Le workflow est **manuel** : rien ne se
compile tout seul, c'est vous qui decidez quand sortir une version.

## 1. Mettre le projet sur GitHub

```bash
cd stocktout
git init
git add .
git commit -m "StockTout 1.0.0"
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/stocktout.git
git push -u origin main
```

## 2. Premiere release

1. Ouvrez le depot sur GitHub.
2. Onglet **Actions** > **Release** > **Run workflow** (bouton a droite).
3. Remplissez :
   - `version` : ex `1.0.0` (vide = version de `pubspec.yaml`).
   - `platforms` : `all` pour tout compiler, ou une seule plateforme.
   - `draft` : `false` = publie directement. Mettez `true` pour relire
     la release en brouillon avant publication (onglet Releases > Draft).
4. Lancez. Duree : ~20-35 min pour les 5 builds.
5. Quand c'est vert, allez dans **Releases** : les 9 fichiers y sont
   (10 avec le AAB si le keystore est configure, publies directement,
   sauf si `draft: true`).
6. Relisez les notes, cliquez **Publish release**.

## 3. Ce qui est compile

| Job | Runner | Sortie |
|---|---|---|
| windows-x64 | windows-2022 (epingle : VS2022) | Setup.exe + ZIP avec `stocktout.exe` |
| macos-x64 | macos-15-intel | DMG + ZIP avec `StockTout.app` |
| macos-arm64 | macos-15 | DMG + ZIP avec `StockTout.app` |
| linux-x64 | ubuntu-22.04 | tar.gz du bundle + .deb |
| android | ubuntu-latest (JDK 17) | APK (+ AAB si keystore) |

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

**Windows** : lancez le `*-setup.exe` (recommande). Assistant en francais
ou anglais, installation sans droits admin (dossier utilisateur), raccourcis
menu Demarrer (+ bureau en option), desinstalleur inclus.
Alternative : le ZIP portable, a decompresser ou vous voulez.
Si SmartScreen affiche un avertissement : "Informations complementaires" >
"Executer quand meme". Pour le supprimer, il faut signer le binaire
(voir section signature).

**macOS** : ouvrez le DMG, glissez `StockTout` vers Applications.
Premier lancement : clic droit > Ouvrir > Ouvrir (bypass Gatekeeper pour les
apps non signees). Le ZIP reste dispo en secours.

**Linux (Ubuntu/Debian)** : double-cliquez le `.deb`, ou :
```bash
sudo dpkg -i stocktout-linux-x64-VERSION-amd64.deb
```
L'app apparait dans le menu avec son icone, et `stocktout` marche dans
le terminal. Alternative portable :
```bash
tar -xzf stocktout-linux-x64-VERSION.tar.gz
./stocktout/stocktout
```
Note : installez `zenity` pour les dialogues de fichiers
(`sudo apt install zenity`).

**Android** : copiez l'APK sur le telephone et ouvrez-le (autorisez les
installations de « sources inconnues » si le telephone le demande).
Aucune permission requise, 100 % hors-ligne. Sans keystore, l'APK est
signe en debug : il s'installe et fonctionne, mais ne peut pas etre
publie sur le Play Store (voir section 8).

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
- **Linux** : pas de signature requise.
- **Android** : keystore de signature, voir section 8. Sans keystore,
  l'APK est signe en debug (installable, pas publiable sur Play).

## 7. Construire les installeurs en local

**Windows** (sur PC Windows avec Flutter + Inno Setup) :
```powershell
flutter build windows --release
iscc packaging\windows\installer.iss /DAppVersion=1.3.0
```

**macOS** (sur Mac avec Flutter) :
```bash
flutter build macos --release
brew install create-dmg
create-dmg --volname "StockTout" --window-size 600 400 --icon-size 100 \
  --icon "StockTout.app" 150 185 --app-drop-link 450 185 \
  stocktout-macos.dmg build/macos/Build/Products/Release/StockTout.app
```

**Linux** (sur Ubuntu/Debian avec Flutter) : `flutter build linux --release`,
puis recopiez le bloc "Build .deb" du workflow (dossier `pkgdeb` +
`dpkg-deb --build`).

**Android** (avec Flutter + SDK Android + JDK 17) :
```bash
flutter build apk --release        # -> build/app/outputs/flutter-apk/
flutter build appbundle --release  # -> build/app/outputs/bundle/
```
Sans `android/key.properties`, la compilation signe en debug
(voir section 8).

## 8. Android : signer en release (keystore)

Le keystore identifie l'editeur. **Gardez-le precieusement : sans lui,
impossible de mettre a jour l'app sur le Play Store.**

### 8.1 Creer le keystore (une fois)

```bash
keytool -genkeypair -v -keystore upload-keystore.jks \
  -alias stocktout -keyalg RSA -keysize 2048 -validity 10000
```

`keytool` est fourni avec le JDK. Notez le mot de passe du keystore,
le mot de passe de la cle et l'alias.

### 8.2 Signer en local

Copiez le keystore dans `android/` (sans le committer, il est ignore
par git) et creez `android/key.properties` (ignore aussi) :

```properties
storePassword=VOTRE_MOT_DE_PASSE_KEYSTORE
keyPassword=VOTRE_MOT_DE_PASSE_CLE
keyAlias=stocktout
storeFile=upload-keystore.jks
```

Puis `flutter build apk --release` / `flutter build appbundle --release`.
Sans ce fichier, la compilation bascule automatiquement sur la
signature debug.

### 8.3 Signer sur GitHub (AAB Play Store)

1. Encodez le keystore en base64 :
   ```bash
   base64 -w0 upload-keystore.jks > keystore.b64   # Linux
   # macOS : base64 -i upload-keystore.jks -o keystore.b64
   ```
2. Depot GitHub > **Settings** > **Secrets and variables** > **Actions** >
   **New repository secret**, ajoutez :
   - `ANDROID_KEYSTORE_B64` : contenu du fichier `keystore.b64`
   - `ANDROID_KEYSTORE_PASSWORD` : mot de passe du keystore
   - `ANDROID_KEY_PASSWORD` : mot de passe de la cle
   - `ANDROID_KEY_ALIAS` : alias (`stocktout`)
3. Relancez le workflow **Release** : l'AAB signe en release est joint
   a la release, pret pour la Play Console.

## 9. CI (auto)

Le workflow `CI` tourne a chaque push : format, analyse, tests.
Il ne publie rien, il verifie juste que le code est sain.

## Polices

Les fichiers Inter sont dans `assets/fonts/` et declares dans `pubspec.yaml`
(famille `Inter`, secours `InterExt` pour les alphabets etendus).

- Licence : SIL Open Font License 1.1, texte complet dans
  `assets/fonts/OFL.txt`. Redistribution autorisee avec le logiciel.
- Pour mettre a jour : remplacer les 8 fichiers `.ttf` (400/500/600/700,
  sous-ensembles latin et latin-ext), rien d'autre a changer.
- Les ecritures non latines (cyrillique, grec, arabe, CJK...) utilisent la
  police systeme : aucun telechargement, aucune dependance reseau.

