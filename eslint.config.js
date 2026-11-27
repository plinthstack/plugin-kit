module.exports = [
	...require( '@wordpress/eslint-plugin' ).configs.recommended,
	{ ignores: [ '**/build/', '**/vendor/' ] },
];
