const { join } = require( 'node:path' );

module.exports = {
	extends: [ '@wordpress/stylelint-config' ],
	overrides: [
		{
			files: [ '**/*.scss' ],
			extends: [ '@wordpress/stylelint-config/scss' ],
		},
	],
	// Relative patterns would resolve against this file's folder inside node_modules, not the plugin.
	ignoreFiles: [ '**/build/**', '**/vendor/**' ].map( ( glob ) => join( process.cwd(), glob ) ),
};
