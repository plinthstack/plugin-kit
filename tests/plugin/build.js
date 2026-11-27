const { cpSync } = require( 'node:fs' );

cpSync( 'src', 'build', {
	recursive: true,
	filter: ( source ) => ! source.endsWith( '.test.js' ),
} );
