module.exports = {
	extends: [ '@wordpress/stylelint-config' ],
	overrides: [
		{
			files: [ '**/*.scss' ],
			extends: [ '@wordpress/stylelint-config/scss' ],
		},
	],
	// Absolute, so stylelint does not resolve them against this file's folder inside node_modules.
	ignoreFiles: [ '/**/build/**', '/**/vendor/**' ],
};
