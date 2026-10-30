#!/usr/bin/env bash
# Runs bin/plugin-kit validate on every fixture and checks its exit code and the field it names.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

check() {
	local out got
	out=$(bin/plugin-kit validate "$1" 2>&1)
	got=$?
	if [ "$got" -ne "$2" ] || { [ -n "${3:-}" ] && [[ "$out" != "$3:"* ]]; }; then
		echo "FAIL $1: exit $got, expected $2${3:+ naming $3}"
		echo "$out"
		fail=1
	else
		echo "ok   $1"
	fi
}

check tests/fixtures/valid.json 0
check tests/fixtures/invalid-missing.json 1 slug
check tests/fixtures/invalid-type.json 1 requires_php
check tests/fixtures/invalid-tier.json 1 tier

exit $fail
