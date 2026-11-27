const { relative, sep } = require( 'node:path' );

// Prettier has no build/ or vendor/ ignores of its own; lint-staged passes absolute paths, so match them from the plugin root.
const own = ( files ) =>
	files.filter( ( file ) => ! /^(?:.*\/)?(?:build|vendor)\//.test( relative( process.cwd(), file ).split( sep ).join( '/' ) ) );
const quoted = ( files ) => files.map( ( file ) => JSON.stringify( file ) ).join( ' ' );

module.exports = {
	'*.php': 'vendor/bin/phpcs',
	'*.{js,jsx,mjs,cjs,ts,tsx}': 'eslint --max-warnings 0 --no-warn-ignored',
	'*.{css,scss}': ( files ) => [
		`stylelint ${ quoted( files ) }`,
		...( own( files ).length ? [ `prettier --check ${ quoted( own( files ) ) }` ] : [] ),
	],
};
