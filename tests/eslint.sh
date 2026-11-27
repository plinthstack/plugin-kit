#!/usr/bin/env bash
# Lints the samples with the kit's ESLint config and with a plugin override, and compares the rule IDs reported.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
root=$PWD

# Runs ESLint in a directory and prints its JSON report; fails on exit 2, a crash or bad config that would otherwise read as clean.
eslint_json() {
	local dir=$1
	shift
	(cd "$dir" || exit 2; "$root/node_modules/.bin/eslint" --format json "$@")
	[ $? -le 1 ]
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
	dir=$(plugin_dir) || return 1
	printf 'var plinthstackDemo = 1\n' | tee "$dir/build/index.js" "$dir/blocks/demo/build/index.js" >"$dir/vendor/demo/index.js"
	cp tests/eslint/clean.js "$dir/src/index.js"
	json=$(eslint_json "$dir" --config "$root/eslint.config.js" .) && files=$(jq -r '.[].filePath' <<<"$json")
	rm -rf "$dir"
	[ "$files" = "$dir/src/index.js" ]
}

lint eslint.config.js tests/eslint/clean.js
report "eslint clean.js" $?
lint eslint.config.js tests/eslint/violation.js tests/eslint/violation.txt
report "eslint violation.js" $?
lint tests/eslint/override/eslint.config.mjs tests/eslint/violation.js tests/eslint/override/violation.txt
report "eslint override violation.js" $?
ignores
report "eslint ignores build/ and vendor/" $?

finish
