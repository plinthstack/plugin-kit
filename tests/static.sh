#!/usr/bin/env bash
# Runs static.yml's plugin-kit.json and version steps on copies of tests/plugin with one file changed, and checks which pass.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# Prints the run script of the static.yml step with the given id or name; fails when there is none.
step() {
	yq -e ".jobs.static.steps[] | select(.id == \"$1\" or .name == \"$1\") | .run" .github/workflows/static.yml
}
if ! read_kit=$(step kit) || ! check=$(step 'Check versions agree'); then
	echo 'FAIL static.yml steps not found'
	exit 1
fi

# Copies the files the steps read from the sample plugin, applies each file and sed edit pair (- deletes the file), and runs both steps in the copy.
# Exits 1 when a step fails, and 2 when an edit fails or changes nothing, so a broken case never passes as a failing step.
versions() {
	local dir status
	dir=$(temp_dir) || return 1
	(
		cp tests/plugin/{plugin-kit.json,plinthstack-demo.php,readme.txt} "$dir" && cd "$dir" || exit 2
		while [ $# -gt 0 ]; do
			if [ "$2" = - ]; then
				rm "$1" || exit 2
			else
				sed -i.bak "$2" "$1" && ! cmp -s "$1" "$1.bak" || exit 2
			fi
			shift 2
		done
		# GitHub runs each step with bash -eo pipefail.
		export GITHUB_OUTPUT=$dir/output
		bash -eo pipefail -c "$read_kit" 2>&1 || exit 1
		SLUG=$(sed -n 's/^slug=//p' output) PREFIX=$(sed -n 's/^prefix=//p' output) bash -eo pipefail -c "$check" 2>&1 || exit 1
	)
	status=$?
	rm -rf "$dir"
	return $status
}

# Passes when versions exits 1, so a step failed rather than the edit, and its output holds the pattern in $expect when set.
fails() {
	local out status
	out=$(versions "$@")
	status=$?
	[ $status -eq 1 ] && grep -q -- "${expect:-}" <<<"$out"
}

versions >/dev/null
report "static versions agree in tests/plugin" $?
versions readme.txt 's/^Stable tag: 1.0.0$/Stable tag: 1.0.0  /' >/dev/null
report "static versions ignore trailing space" $?
versions plugin-kit.json $'s/$/\r/' plinthstack-demo.php $'s/$/\r/' readme.txt $'s/$/\r/' >/dev/null
report "static versions ignore CRLF line endings" $?
versions plinthstack-demo.php "s#^define( 'PLINTHSTACK_DEMO_VERSION', '1.0.0' );\$#\tdefine( 'PLINTHSTACK_DEMO_VERSION', '1.0.0' ); // Version.#" >/dev/null
report "static versions read an indented define with a comment" $?
versions plinthstack-demo.php $'s#^define( \'PLINTHSTACK_DEMO_VERSION\', \'1.0.0\' );$#&\\\n * Version: 9.9.9#' >/dev/null
report "static versions read only the first Version header" $?
fails plinthstack-demo.php 's/Version:     1.0.0/Version:     1.0.1/'
report "static versions fail on a different header" $?
fails plinthstack-demo.php "s/'1.0.0' );/'1.0.1' );/"
report "static versions fail on a different constant" $?
fails readme.txt 's/^Stable tag: 1.0.0$/Stable tag: 1.0.1/'
report "static versions fail on a different stable tag" $?
fails plugin-kit.json 's/"prefix": "plinthstack_demo"/"prefix": "plinthstack_other"/'
report "static versions fail when the constant is not the prefix's" $?
fails plinthstack-demo.php '/1\.0\.0/d' readme.txt '/^Stable tag/d'
report "static versions fail when no line is found" $?
expect="readme.txt not found" fails readme.txt -
report "static versions fail without readme.txt" $?
fails plugin-kit.json '/"prefix"/d'
report "static fails on plugin-kit.json without a prefix" $?
fails plugin-kit.json '/"requires_php"/d'
report "static fails on plugin-kit.json without requires_php" $?

finish
