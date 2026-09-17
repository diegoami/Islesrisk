#!/usr/bin/env bash
#
# Malpaco quality gates: format, lint, test, export.
#
# Run them all with ./tools/gates.sh. The committed pre-push hook runs this,
# so a push that would turn CI red is stopped on your machine instead.
#
# Godot binary: set GODOT_BIN, or have `godot` on PATH.
#   export GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64
#
# The export gate is SKIPPED when export templates aren't installed, so a
# contributor who only touches core/ isn't forced into a 1 GB download. CI
# sets MALPACO_REQUIRE_EXPORT=1 to make it mandatory there.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

GODOT="${GODOT_BIN:-godot}"
SOURCES=(core game test)
FAILED=()
SKIPPED=()

say() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok() { printf '\033[32mPASS\033[0m  %s\n' "$1"; }
bad() { printf '\033[31mFAIL\033[0m  %s\n' "$1"; FAILED+=("$1"); }
skip() { printf '\033[33mSKIP\033[0m  %s — %s\n' "$1" "$2"; SKIPPED+=("$1"); }

if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
	echo "Godot not found: '$GODOT'." >&2
	echo "Set GODOT_BIN to the 4.7.x binary, or put 'godot' on PATH. See ONBOARDING.md." >&2
	exit 127
fi

# --- 1. format --------------------------------------------------------------
say "format (gdformat --check)"
if ! command -v gdformat >/dev/null 2>&1; then
	skip "format" "gdformat missing — pip install \"gdtoolkit==4.*\""
elif gdformat --check "${SOURCES[@]}"; then
	ok "format"
else
	bad "format — run: gdformat ${SOURCES[*]}"
fi

# --- 2. lint ----------------------------------------------------------------
say "lint (gdlint)"
if ! command -v gdlint >/dev/null 2>&1; then
	skip "lint" "gdlint missing — pip install \"gdtoolkit==4.*\""
elif gdlint "${SOURCES[@]}"; then
	ok "lint"
else
	bad "lint"
fi

# --- 3. test ----------------------------------------------------------------
# The import pass is load-bearing: without it, class_name globals are not
# registered and every suite fails with "Identifier not declared".
say "test (gdUnit4, headless)"
"$GODOT" --path . --headless --import >/dev/null 2>&1
if "$GODOT" --path . --headless -s -d --remote-debug tcp://127.0.0.1:0 \
	res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a test --ignoreHeadlessMode -c; then
	ok "test"
else
	bad "test"
fi

# --- 4. export --------------------------------------------------------------
say "export (Linux release build)"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/4.7.2.stable"
if [[ ! -d "$TEMPLATE_DIR" ]]; then
	if [[ "${MALPACO_REQUIRE_EXPORT:-0}" == "1" ]]; then
		bad "export — templates missing at $TEMPLATE_DIR"
	else
		skip "export" "no export templates; Godot > Project > Install Export Templates"
	fi
else
	mkdir -p build/linux
	if "$GODOT" --path . --headless --export-release "Linux" build/linux/malpaco.x86_64 2>&1 |
		grep -viE "alsa|audio driver"; then
		if [[ -x build/linux/malpaco.x86_64 ]]; then
			ok "export — build/linux/malpaco.x86_64"
		else
			bad "export — Godot reported success but produced no binary"
		fi
	else
		bad "export"
	fi
fi

# --- summary ----------------------------------------------------------------
say "summary"
for s in "${SKIPPED[@]:-}"; do [[ -n "$s" ]] && printf '\033[33mskipped\033[0m %s\n' "$s"; done
if ((${#FAILED[@]})); then
	printf '\033[31m%d gate(s) failed:\033[0m %s\n' "${#FAILED[@]}" "${FAILED[*]}"
	exit 1
fi
printf '\033[32mall gates green\033[0m\n'
