const config = require( '@wordpress/prettier-config' );

// Set explicitly: @wordpress/prettier-config only adds it when the prettier it resolves is wp-prettier,
// and npm can dedupe the kit's fork onto a plugin's upstream prettier. Upstream then warns on the option.
module.exports = {
	...config,
	parenSpacing: true,
	overrides: config.overrides.map( ( override ) => ( {
		...override,
		options: { ...override.options, parenSpacing: false },
	} ) ),
};
