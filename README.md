# J.A.R.V.I.S. Mobile

Iron Man style personal AI assistant (Flutter).

## New GitHub repo (phone or PC)

1. Create a **new empty** repository on GitHub (no README needed).
2. Upload **everything inside this zip** to the repo root  
   (or on PC: unzip → `git init` → add remote → push).
3. Open **Actions** → wait for **Build Android APK**.
4. Download artifact **jarvis-apk** → install on phone.

## First launch
- Enter your OpenAI API key
- Settings → Biometric Lock (after fingerprint works)
- Settings → GitHub: PAT (`repo` scope) + `owner/repo` for self-update

## Features
- Voice in/out, tools, Discord DM auto-reply, FiveM monitor
- GitHub self-improve tools
- Biometrics (`FlutterFragmentActivity` already set)

## Local (optional)
```bash
flutter pub get
flutter run
```
