#!/usr/bin/env bash
# Formats the samples with the kit's Prettier config and with a plugin override, and compares the output.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

# Formats a sample with a config and diffs the result against the expected file.
format() {
	if diff -u "$3" <(node_modules/.bin/prettier --config "$1" "$2"); then
		echo "ok   prettier $1 $2"
	else
		echo "FAIL prettier $1 $2"
		fail=1
	fi
}

format prettier.config.js tests/prettier/input.js tests/prettier/expected.js
format prettier.config.js tests/prettier/input.css tests/prettier/expected.css
format tests/prettier/override/.prettierrc.js tests/prettier/input.js tests/prettier/override/expected.js

# Loads the kit's config with @wordpress/prettier-config as it is when it resolves upstream prettier.
if node -e "
	const wp = require.resolve( '@wordpress/prettier-config' );
	const upstream = { ...require( wp ), overrides: [ { files: '*.{css,sass,scss}', options: { singleQuote: false } } ] };
	delete upstream.parenSpacing;
	require.cache[ wp ] = { id: wp, filename: wp, loaded: true, exports: upstream };
	const c = require( './prettier.config.js' );
	process.exit( c.parenSpacing === true && c.overrides.length > 0 && c.overrides.every( ( o ) => o.options.parenSpacing === false ) ? 0 : 1 );
"; then
	echo "ok   prettier sets parenSpacing explicitly"
else
	echo "FAIL prettier leaves parenSpacing to @wordpress/prettier-config"
	fail=1
fi

exit $fail
