#!/usr/bin/env bash
# Lints the samples with the kit's stylelint config and with a plugin override, and checks it agrees with the kit's Prettier config.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
root=$PWD

# Runs stylelint in a directory and prints its JSON report; fails on any exit but 0 (clean) or 2 (problems), such as a crash.
stylelint_json() {
	local dir=$1 report status
	shift
	report=$(temp_dir) || return 1
	(cd "$dir" || exit 1; "$root/node_modules/.bin/stylelint" --formatter json --output-file "$report/report.json" "$@" >/dev/null 2>&1)
	status=$?
	{ [ $status -eq 0 ] || [ $status -eq 2 ]; } && cat "$report/report.json"
	status=$?
	rm -rf "$report"
	return $status
}

# Lints a sample with a config and diffs its sorted, unique rule IDs against the expected list (empty when omitted); a deprecated or invalid rule option also fails.
lint() {
	local expected=${3:-/dev/null} json ids
	json=$(stylelint_json "$root" --config "$1" "$2") || return 1
	jq -e 'all( .[]; ( .invalidOptionWarnings + .deprecations ) == [] )' <<<"$json" >/dev/null || return 1
	ids=$(jq -r '.[].warnings[].rule' <<<"$json") || return 1
	diff -u "$expected" <([ -z "$ids" ] || printf '%s\n' "$ids" | LC_ALL=C sort -u)
}

# Lints a plugin whose config extends the kit's, in a path with glob characters, through the CLI or with "api" through stylelint.lint() from the repo root, and checks only its own source was linted, not build/ or vendor/ at any depth.
ignores() {
	local dir plugin json files=
	dir=$(plugin_dir) || return 1
	plugin="$dir/demo (copy)"
	mkdir "$plugin" && mv "$dir/src" "$dir/build" "$dir/vendor" "$dir/blocks" "$plugin/" || return 1
	printf '{ "extends": "%s/stylelint.config.js" }\n' "$root" >"$plugin/.stylelintrc.json"
	printf '.a { color: white; }\n' | tee "$plugin/build/style.css" "$plugin/blocks/demo/build/style.css" >"$plugin/vendor/demo/style.css"
	cp tests/stylelint/clean.css "$plugin/src/style.css"
	if [ "${1:-}" = api ]; then
		files=$(node --input-type=module -e "
			const { default: stylelint } = await import( '$root/node_modules/stylelint/lib/index.mjs' );
			const { results } = await stylelint.lint( { cwd: process.argv[ 1 ], files: '**/*.css' } );
			console.log( results.filter( ( r ) => ! r.ignored ).map( ( r ) => r.source ).join( '\\n' ) );
		" "$plugin")
	else
		json=$(stylelint_json "$plugin" '**/*.css') && files=$(jq -r '.[] | select(.ignored != true) | .source' <<<"$json")
	fi
	rm -rf "$dir"
	[ "$files" = "$plugin/src/style.css" ]
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
	lint stylelint.config.js "tests/stylelint/$sample" "tests/stylelint/$sample.txt"
	report "stylelint $sample" $?
done
lint tests/stylelint/override/.stylelintrc.json tests/stylelint/violation.css tests/stylelint/override/violation.css.txt
report "stylelint override violation.css" $?
ignores
report "stylelint ignores build/ and vendor/" $?
ignores api
report "stylelint ignores build/ and vendor/ through the API with another cwd" $?
agrees tests/prettier/input.css css
report "stylelint agrees with Prettier on tests/prettier/input.css" $?
agrees tests/stylelint/violation.scss scss
report "stylelint agrees with Prettier on tests/stylelint/violation.scss" $?

finish
