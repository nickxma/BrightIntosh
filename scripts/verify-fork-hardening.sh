#!/bin/bash

set -euo pipefail

fail() {
    echo "fork hardening verification failed: $1" >&2
    exit 1
}

grep -q 'func applicationWillTerminate' BrightIntosh/AppDelegate.swift \
    || fail "application termination hook is missing"
grep -q 'brightnessManager?.shutdown(reason: "application terminating")' BrightIntosh/AppDelegate.swift \
    || fail "application termination does not synchronously shut down brightness"
grep -q 'func shutdown(reason: String)' BrightIntosh/BrightnessManager.swift \
    || fail "brightness manager shutdown API is missing"
grep -q 'NSApplication.shared.terminate(nil)' BrightIntosh/UI/StatusBarMenu.swift \
    || fail "menu-bar Quit bypasses the application termination lifecycle"

if sed -n '/@objc func exitBrightIntosh()/,/^    }/p' BrightIntosh/UI/StatusBarMenu.swift \
    | grep -q 'exit(0)'; then
    fail "menu-bar Quit still exits before display restoration"
fi

grep -q 'useAlternateBrightnessBackend", defaultValue: false' BrightIntosh/BrightIntoshSettings.swift \
    || fail "compatibility overlay backend is no longer opt-in"
grep -q 'may lose increased brightness in Mission Control' BrightIntosh/UI/SettingsWindow.swift \
    || fail "compatibility overlay warning is missing"

echo "Fork hardening verification passed."
