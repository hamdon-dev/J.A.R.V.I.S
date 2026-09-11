#!/usr/bin/env python3
"""Patch Flutter-generated Android project for Jarvis — valid XML only."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(".")
ANDROID = ROOT / "android"

SERVICE_BLOCK = """
        <service android:name="notification.listener.service.NotificationListener" android:label="J.A.R.V.I.S" android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" android:exported="true">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService"/>
            </intent-filter>
        </service>
"""


def find_main_activities() -> list[Path]:
    hits: list[Path] = []
    for base in (
        ANDROID / "app" / "src" / "main" / "kotlin",
        ANDROID / "app" / "src" / "main" / "java",
    ):
        if not base.exists():
            continue
        hits.extend(base.rglob("MainActivity.kt"))
        hits.extend(base.rglob("MainActivity.java"))
    return hits


def patch_main_activity(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    original = text
    text = text.replace(
        "io.flutter.embedding.android.FlutterActivity",
        "io.flutter.embedding.android.FlutterFragmentActivity",
    )
    text = text.replace("FlutterActivity()", "FlutterFragmentActivity()")
    text = text.replace("extends FlutterActivity", "extends FlutterFragmentActivity")
    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"Patched FragmentActivity: {path}")
    else:
        print(f"MainActivity already OK: {path}")


def patch_manifest() -> None:
    man = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    if not man.exists():
        raise SystemExit("AndroidManifest.xml missing")

    text = man.read_text(encoding="utf-8")

    # Permissions — insert right after opening <manifest ...> tag
    perms = [
        "android.permission.USE_BIOMETRIC",
        "android.permission.USE_FINGERPRINT",
        "android.permission.RECORD_AUDIO",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.WAKE_LOCK",
        "android.permission.VIBRATE",
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
    ]
    for perm in perms:
        if perm in text:
            continue
        line = f'    <uses-permission android:name="{perm}"/>\n'
        text = re.sub(r"(<manifest\b[^>]*>\s*)", r"\1" + line, text, count=1)
        print(f"Added permission: {perm}")

    # Cleartext: only add attribute if missing, keep tag valid
    if "usesCleartextTraffic" not in text:
        text = re.sub(
            r"<application\b",
            '<application android:usesCleartextTraffic="true"',
            text,
            count=1,
        )
        print("Enabled cleartext traffic")

    # Application label
    if re.search(r'<application\b[^>]*android:label=', text):
        text = re.sub(
            r'(<application\b[^>]*android:label=")([^"]*)(")',
            r'\1J.A.R.V.I.S\3',
            text,
            count=1,
        )
        print("Set application label to J.A.R.V.I.S")

    # Notification listener service
    if "notification.listener.service.NotificationListener" not in text:
        if "</application>" not in text:
            raise SystemExit("No </application> in manifest")
        text = text.replace("</application>", SERVICE_BLOCK + "    </application>", 1)
        print("Injected NotificationListener service")
    else:
        print("NotificationListener service already present")

    # Basic well-formedness checks
    if text.count("<application") != text.count("</application>"):
        raise SystemExit("Manifest application tags unbalanced after patch")
    if "<manifest" not in text or "</manifest>" not in text:
        raise SystemExit("Manifest root broken after patch")

    man.write_text(text, encoding="utf-8")
    print(f"Manifest updated: {man}")
    print("--- manifest preview ---")
    print(man.read_text(encoding="utf-8")[:2500])


def patch_min_sdk() -> None:
    for name in ("build.gradle", "build.gradle.kts"):
        bg = ANDROID / "app" / name
        if not bg.exists():
            continue
        text = bg.read_text(encoding="utf-8")
        original = text
        text = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 26", text)
        text = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 26", text)
        text = re.sub(r"minSdkVersion\s+\d+", "minSdkVersion 26", text)
        text = re.sub(r"minSdk\s*=\s*\d+", "minSdk = 26", text)
        if text != original:
            bg.write_text(text, encoding="utf-8")
            print(f"minSdk → 26 in {bg}")
        else:
            print(f"minSdk note: {bg}")


def main() -> None:
    if not ANDROID.exists():
        raise SystemExit("android/ folder missing — run flutter create first")
    for act in find_main_activities():
        patch_main_activity(act)
    patch_manifest()
    patch_min_sdk()
    print("patch_android.py complete")


if __name__ == "__main__":
    main()
