const assert = require( 'node:assert' );
const test = require( 'node:test' );
const { greeting } = require( './greeting' );

test( 'greets by name', () => {
	assert.strictEqual( greeting( 'Ada' ), 'Hello, Ada' );
} );
