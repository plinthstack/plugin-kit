<?php
/**
 * The plugin-kit command line.
 *
 * @package PlinthStack\PluginKit
 */

namespace PlinthStack\PluginKit;

/**
 * Dispatches plugin-kit commands.
 */
class Cli {

	/**
	 * Runs the command named in the arguments.
	 *
	 * @param string[] $argv Command-line arguments, script name first.
	 * @return int Exit code: 0 valid, 1 invalid, 2 usage error.
	 */
	public static function run( array $argv ): int {
		if ( 'validate' !== ( $argv[1] ?? '' ) ) {
			fwrite( STDERR, "Usage: plugin-kit validate [path]\n" );
			return 2;
		}

		$path   = $argv[2] ?? 'plugin-kit.json';
		$errors = Validate::errors( $path );

		foreach ( $errors as $error ) {
			fwrite( STDERR, $error . "\n" );
		}
		if ( $errors ) {
			return 1;
		}
		fwrite( STDOUT, "{$path} is valid\n" );
		return 0;
	}
}
