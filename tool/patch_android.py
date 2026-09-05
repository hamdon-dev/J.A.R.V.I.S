#!/usr/bin/env python3
"""Patch Flutter-generated Android project for Jarvis (biometrics + minSdk)."""
from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path(".")
ANDROID = ROOT / "android"


def find_main_activities() -> list[Path]:
    hits: list[Path] = []
    for base in (ANDROID / "app" / "src" / "main" / "kotlin", ANDROID / "app" / "src" / "main" / "java"):
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
        "android.permission.WAKE_LOCK",
        "android.permission.VIBRATE",
        "android.permission.INTERNET",
    ]
    for p in perms:
        tag = f'<uses-permission android:name="{p}"/>'
        if p.split(".")[-1] not in text and tag not in text:
            # insert after <manifest ...>
            text = re.sub(
                r"(<manifest\b[^>]*>)",
                r"\1\n    " + tag,
                text,
                count=1,
            )
            print(f"Added permission: {p}")
    # cleartext for LAN/sync if needed
    if "usesCleartextTraffic" not in text:
        text = text.replace(
            "<application",
            '<application android:usesCleartextTraffic="true"',
            1,
        )
    man.write_text(text, encoding="utf-8")
    print(f"Manifest updated: {man}")


def patch_min_sdk() -> None:
    # Prefer Groovy build.gradle, also try Kotlin DSL
    candidates = [
        ANDROID / "app" / "build.gradle",
        ANDROID / "app" / "build.gradle.kts",
    ]
    for path in candidates:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        # minSdk / minSdkVersion -> at least 26 (local_auth)
        text = re.sub(
            r"minSdkVersion\s+\d+",
            "minSdkVersion 26",
            text,
        )
        text = re.sub(
            r"minSdk\s*=\s*\d+",
            "minSdk = 26",
            text,
        )
        text = re.sub(
            r"minSdk\s+\d+",
            "minSdk 26",
            text,
        )
        # flutter.minSdkVersion pattern
        text = re.sub(
            r"minSdk\s*=\s*flutter\.minSdkVersion",
            "minSdk = 26",
            text,
        )
        text = re.sub(
            r"minSdkVersion\s+flutter\.minSdkVersion",
            "minSdkVersion 26",
            text,
        )
        if text != original:
            path.write_text(text, encoding="utf-8")
            print(f"minSdk set to 26: {path}")
        else:
            print(f"minSdk patch not applied (check manually): {path}")
        return
    print("WARNING: app build.gradle not found")


def main() -> None:
    if not ANDROID.exists():
        raise SystemExit("android/ folder missing — run flutter create first")
    acts = find_main_activities()
    if not acts:
        print("WARNING: no MainActivity found")
    for a in acts:
        patch_main_activity(a)
    patch_manifest()
    patch_min_sdk()
    print("Android patch complete.")


if __name__ == "__main__":
    main()
