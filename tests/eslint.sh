#!/usr/bin/env bash
# Lints the samples with the kit's ESLint config and with a plugin override, and compares the rule IDs reported.
set -u
cd "$(dirname "$0")/.." || exit 1
root=$PWD
fail=0

# Runs ESLint in a directory and prints its JSON report; fails on exit 2, a crash or bad config that would otherwise read as clean.
eslint_json() {
	local dir=$1
	shift
	(cd "$dir" || exit 2; "$root/node_modules/.bin/eslint" --format json "$@")
	[ $? -le 1 ]
}

# Prints "ok" or "FAIL" for a check name from the exit status of the check.
report() {
	if [ "$2" -eq 0 ]; then
		echo "ok   eslint $1"
	else
		echo "FAIL eslint $1"
		fail=1
	fi
}

# Lints a sample with a config and diffs its sorted, unique rule IDs against the expected list (empty when omitted).
lint() {
	local expected=${3:-/dev/null} json ids
	json=$(eslint_json "$root" --config "$1" "$2") || return 1
	ids=$(jq -r '.[].messages[].ruleId' <<<"$json") || return 1
	diff -u "$expected" <([ -z "$ids" ] || printf '%s\n' "$ids" | LC_ALL=C sort -u)
}

# Lints a plugin-shaped folder and checks only its own source was linted, not build/ or vendor/ at any depth.
ignores() {
	local dir json files=
	# A failed mktemp would leave dir empty, and cd "" stays in the repo that rm -rf then deletes.
	dir=$(mktemp -d) && [ -d "$dir" ] && dir=$(cd "$dir" && pwd -P) || return 1
	mkdir -p "$dir/build" "$dir/vendor/demo" "$dir/blocks/demo/build" "$dir/src"
	printf 'var plinthstackDemo = 1\n' | tee "$dir/build/index.js" "$dir/blocks/demo/build/index.js" >"$dir/vendor/demo/index.js"
	cp tests/eslint/clean.js "$dir/src/index.js"
	json=$(eslint_json "$dir" --config "$root/eslint.config.js" .) && files=$(jq -r '.[].filePath' <<<"$json")
	rm -rf "$dir"
	[ "$files" = "$dir/src/index.js" ]
}

lint eslint.config.js tests/eslint/clean.js
report clean.js $?
lint eslint.config.js tests/eslint/violation.js tests/eslint/violation.txt
report violation.js $?
lint tests/eslint/override/eslint.config.mjs tests/eslint/violation.js tests/eslint/override/violation.txt
report "override violation.js" $?
ignores
report "ignores build/ and vendor/" $?

exit $fail
