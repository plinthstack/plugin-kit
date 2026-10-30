<?php
/**
 * Checks a plugin-kit.json file against the schema.
 *
 * @package PlinthStack\PluginKit
 */

namespace PlinthStack\PluginKit;

use JsonSchema\Validator;

/**
 * Validates plugin-kit.json files.
 */
class Validate {

	/**
	 * Returns the problems found in a plugin-kit.json file.
	 *
	 * @param string $path Path to the file.
	 * @return string[] One message per problem, each naming its field; empty when valid.
	 */
	public static function errors( string $path ): array {
		if ( ! is_file( $path ) || ! is_readable( $path ) ) {
			return array( "{$path}: file not found" );
		}

		$data = json_decode( (string) file_get_contents( $path ) );
		if ( JSON_ERROR_NONE !== json_last_error() ) {
			return array( "{$path}: " . json_last_error_msg() );
		}

		$schema    = json_decode( (string) file_get_contents( dirname( __DIR__ ) . '/schema/plugin-kit.schema.json' ) );
		$validator = new Validator();
		$validator->validate( $data, $schema );

		$errors = array();
		foreach ( $validator->getErrors() as $error ) {
			$field    = '' !== $error['property'] ? $error['property'] : '(root)';
			$errors[] = "{$field}: {$error['message']}";
		}
		return $errors;
	}
}
