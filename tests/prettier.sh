#!/usr/bin/env bash
# Formats the samples with the kit's Prettier config and with a plugin override, and compares the output.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

# Formats a sample with a config and diffs the result against the expected file.
format() {
	diff -u "$3" <(node_modules/.bin/prettier --config "$1" "$2")
	report "prettier $1 $2" $?
}

format prettier.config.js tests/prettier/input.js tests/prettier/expected.js
format prettier.config.js tests/prettier/input.css tests/prettier/expected.css
format tests/prettier/override/.prettierrc.js tests/prettier/input.js tests/prettier/override/expected.js

# Loads the kit's config with @wordpress/prettier-config as it is when it resolves upstream prettier.
node -e "
	const wp = require.resolve( '@wordpress/prettier-config' );
	const upstream = { ...require( wp ), overrides: [ { files: '*.{css,sass,scss}', options: { singleQuote: false } } ] };
	delete upstream.parenSpacing;
	require.cache[ wp ] = { id: wp, filename: wp, loaded: true, exports: upstream };
	const c = require( './prettier.config.js' );
	process.exit( c.parenSpacing === true && c.overrides.length > 0 && c.overrides.every( ( o ) => o.options.parenSpacing === false ) ? 0 : 1 );
"
report "prettier sets parenSpacing explicitly" $?

finish
