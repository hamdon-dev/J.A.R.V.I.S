#!/usr/bin/env python3
"""Patch Flutter-generated Android project for Jarvis."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(".")
ANDROID = ROOT / "android"

NOTIFICATION_SERVICE = '''
        <!-- Required so J.A.R.V.I.S appears under Notification access -->
        <service
            android:name="notification.listener.service.NotificationListener"
            android:label="J.A.R.V.I.S"
            android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.service.notification.NotificationListenerService" />
            </intent-filter>
        </service>
'''


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
        print("WARNING: AndroidManifest.xml missing")
        return
    text = man.read_text(encoding="utf-8")

    perms = [
        "android.permission.USE_BIOMETRIC",
        "android.permission.USE_FINGERPRINT",
        "android.permission.RECORD_AUDIO",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
        "android.permission.WAKE_LOCK",
        "android.permission.VIBRATE",
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
    ]
    for p in perms:
        if p not in text:
            text = re.sub(
                r"(<manifest\b[^>]*>)",
                r"\1\n    <uses-permission android:name=\"" + p + r"\"/>",
                text,
                count=1,
            )
            print(f"Added permission: {p}")

    if "usesCleartextTraffic" not in text:
        text = text.replace(
            "<application",
            '<application android:usesCleartextTraffic="true"',
            1,
        )
        print("Enabled cleartext traffic")

    # App label so it is easy to find in Samsung lists
    if 'android:label=' in text and "J.A.R.V.I.S" not in text:
        text = re.sub(
            r'android:label="[^"]*"',
            'android:label="J.A.R.V.I.S"',
            text,
            count=1,
        )
        print("Set application label to J.A.R.V.I.S")

    # Critical: notification listener service (must be in *app* manifest)
    if "NotificationListenerService" not in text and "notification.listener.service.NotificationListener" not in text:
        if "</application>" in text:
            text = text.replace("</application>", NOTIFICATION_SERVICE + "\n    </application>", 1)
            print("Injected NotificationListener service")
        else:
            print("WARNING: could not find </application> to inject service")
    else:
        print("NotificationListener service already present")
        # Ensure label is J.A.R.V.I.S for the service
        text = re.sub(
            r'(android:name="notification\.listener\.service\.NotificationListener"[^>]*android:label=")([^"]*)(")',
            r'\1J.A.R.V.I.S\3',
            text,
        )

    man.write_text(text, encoding="utf-8")
    print(f"Manifest updated: {man}")


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
            print(f"minSdk already patched or pattern not found: {bg}")


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
