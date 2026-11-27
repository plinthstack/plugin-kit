#!/usr/bin/env bash
# Lints the samples with the kit's stylelint config and with a plugin override, and checks it agrees with the kit's Prettier config.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
root=$PWD

# Runs stylelint in a directory and prints its JSON report; fails on any exit but 0 (clean) or 2 (problems), such as a crash.
stylelint_json() {
	local dir=$1 status
	shift
	(cd "$dir" || exit 1; "$root/node_modules/.bin/stylelint" --formatter json "$@" 2>&1)
	status=$?
	[ $status -eq 0 ] || [ $status -eq 2 ]
}

# Lints a sample with a config and diffs its sorted, unique rule IDs against the expected list (empty when omitted).
lint() {
	local expected=${3:-/dev/null} json ids
	json=$(stylelint_json "$root" --config "$1" "$2") || return 1
	ids=$(jq -r '.[].warnings[].rule' <<<"$json") || return 1
	diff -u "$expected" <([ -z "$ids" ] || printf '%s\n' "$ids" | LC_ALL=C sort -u)
}

# Lints a plugin-shaped folder and checks only its own source was linted, not build/ or vendor/ at any depth.
ignores() {
	local dir json files=
	dir=$(plugin_dir) || return 1
	printf '.a { color: white; }\n' | tee "$dir/build/style.css" "$dir/blocks/demo/build/style.css" >"$dir/vendor/demo/style.css"
	cp tests/stylelint/clean.css "$dir/src/style.css"
	json=$(stylelint_json "$dir" --config "$root/stylelint.config.js" '**/*.css') && files=$(jq -r '.[] | select(.ignored != true) | .source' <<<"$json")
	rm -rf "$dir"
	[ "$files" = "$dir/src/style.css" ]
}

# Formats a stylesheet with the kit's Prettier config, applies stylelint's fixes, and checks Prettier accepts the result unchanged.
agrees() {
	local dir file status
	dir=$(temp_dir) || return 1
	file=$dir/style.$2
	node_modules/.bin/prettier --config prettier.config.js --stdin-filepath "style.$2" <"$1" >"$file" &&
		{ node_modules/.bin/stylelint --config stylelint.config.js --fix "$file" >/dev/null 2>&1; status=$?; [ $status -eq 0 ] || [ $status -eq 2 ]; } &&
		node_modules/.bin/prettier --config prettier.config.js --check "$file" >/dev/null 2>&1
	status=$?
	rm -rf "$dir"
	return $status
}

for sample in clean.css clean.scss; do
	lint stylelint.config.js "tests/stylelint/$sample"
	report "stylelint $sample" $?
done
for sample in violation.css violation.scss; do
	lint stylelint.config.js "tests/stylelint/$sample" "tests/stylelint/${sample%.*}.${sample##*.}.txt"
	report "stylelint $sample" $?
done
lint tests/stylelint/override/stylelint.config.mjs tests/stylelint/violation.css tests/stylelint/override/violation.css.txt
report "stylelint override violation.css" $?
ignores
report "stylelint ignores build/ and vendor/" $?
agrees tests/prettier/input.css css
report "stylelint agrees with Prettier on tests/prettier/input.css" $?
agrees tests/stylelint/violation.scss scss
report "stylelint agrees with Prettier on tests/stylelint/violation.scss" $?

finish
