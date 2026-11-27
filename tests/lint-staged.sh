#!/usr/bin/env bash
# Commits staged samples in a throwaway plugin repo through the kit's lint-staged config and checks which commits it blocks, and by which tool.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"
root=$PWD

# Fills a git repo with a plugin that loads the kit (linked in as kit/) for lint-staged, PHPCS, ESLint, stylelint and Prettier.
plugin_repo() {
	local dir=$1
	ln -s "$root" "$dir/kit" && ln -s "$root/node_modules" "$dir/node_modules" && ln -s "$root/vendor" "$dir/vendor" || return 1
	echo "module.exports = require( './kit/lint-staged.config.js' );" >"$dir/.lintstagedrc.cjs"
	echo "module.exports = require( './kit/prettier.config.js' );" >"$dir/.prettierrc.js"
	echo "module.exports = require( './kit/eslint.config.js' );" >"$dir/eslint.config.js"
	echo '{ "extends": "./kit/stylelint.config.js" }' >"$dir/.stylelintrc.json"
	sed 's#\.\./\.\./phpcs/ruleset\.xml#kit/phpcs/ruleset.xml#' tests/phpcs/phpcs.xml >"$dir/phpcs.xml"
	printf 'kit\nnode_modules\nvendor\n' >"$dir/.gitignore"
	git -C "$dir" init -q && git -C "$dir" add -A &&
		git -C "$dir" -c user.name=demo -c user.email=demo@example.com -c commit.gpgsign=false commit -q -m init
}

# Stages one sample at a path and runs lint-staged; with no tool it must pass, with a tool (a task's command prefix) only that task may fail.
# A fourth argument puts the plugin repo in that subfolder of the temporary folder.
staged() {
	local sample=$1 path=$2 tool=${3:-} dir repo out status
	dir=$(temp_dir) || return 1
	repo="$dir/${4:-.}"
	mkdir -p "$repo" && plugin_repo "$repo" && mkdir -p "$(dirname "$repo/$path")" && cp "$sample" "$repo/$path" && git -C "$repo" add -f "$path" &&
		out=$(cd "$repo" && node_modules/.bin/lint-staged 2>&1)
	status=$?
	rm -rf "$dir"
	if [ -z "$tool" ]; then
		[ $status -eq 0 ]
	else
		[ $status -eq 1 ] && grep -q "^✖ $tool.*:\$" <<<"$out" && [ "$(grep -c '^✖ .*:$' <<<"$out")" -eq 1 ] && ! grep -q 'spawn' <<<"$out"
	fi
}

staged tests/phpcs/clean.php src/clean.php
report "lint-staged passes clean.php" $?
staged tests/phpcs/violation.php src/violation.php vendor/bin/phpcs
report "lint-staged blocks a PHPCS violation" $?
staged tests/eslint/clean.js src/clean.js
report "lint-staged passes clean.js" $?
staged tests/eslint/violation.js src/violation.js eslint
report "lint-staged blocks an ESLint violation" $?
staged tests/lint-staged/warning.js src/warning.js eslint
report "lint-staged blocks an ESLint warning" $?
staged tests/lint-staged/fixable.js src/fixable.js eslint
report "lint-staged blocks a fixable ESLint problem instead of fixing it" $?
staged tests/eslint/violation.js build/violation.js
report "lint-staged skips build/ for ESLint" $?
staged tests/stylelint/clean.scss src/clean.scss
report "lint-staged passes clean.scss" $?
staged tests/stylelint/violation.css src/violation.css stylelint
report "lint-staged blocks a stylelint violation" $?
staged tests/lint-staged/fixable.css src/fixable.css stylelint
report "lint-staged blocks a fixable stylelint problem instead of fixing it" $?
staged tests/lint-staged/unformatted.css src/unformatted.css 'prettier --check'
report "lint-staged blocks a stylesheet Prettier would reformat" $?
staged tests/lint-staged/unformatted.css src/unformatted.css 'prettier --check' build/demo
report "lint-staged runs Prettier in a plugin under a folder named build" $?
staged tests/stylelint/violation.css build/violation.css
report "lint-staged skips build/ for stylelint" $?
staged tests/lint-staged/unformatted.css "build/unformatted (copy).css"
report "lint-staged skips build/ for Prettier" $?
staged tests/lint-staged/unformatted.css blocks/demo/build/unformatted.css
report "lint-staged skips a nested build/ for Prettier" $?

finish
