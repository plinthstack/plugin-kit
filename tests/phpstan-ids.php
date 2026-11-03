<?php
/**
 * Prints identifier:line for each error in PHPStan's JSON output on stdin; errors outside a file print as none:0.
 *
 * @package PlinthStack\PluginKit
 */

$plugin_kit_report = json_decode( (string) stream_get_contents( STDIN ), true );
$plugin_kit_files  = is_array( $plugin_kit_report ) && is_array( $plugin_kit_report['files'] ?? null ) ? $plugin_kit_report['files'] : array();
foreach ( $plugin_kit_files as $plugin_kit_file ) {
	$plugin_kit_messages = is_array( $plugin_kit_file ) && is_array( $plugin_kit_file['messages'] ?? null ) ? $plugin_kit_file['messages'] : array();
	foreach ( $plugin_kit_messages as $plugin_kit_message ) {
		$plugin_kit_message = is_array( $plugin_kit_message ) ? $plugin_kit_message : array();
		$plugin_kit_id      = is_string( $plugin_kit_message['identifier'] ?? null ) ? $plugin_kit_message['identifier'] : 'none';
		$plugin_kit_line    = is_int( $plugin_kit_message['line'] ?? null ) ? $plugin_kit_message['line'] : 0;
		fwrite( STDOUT, "{$plugin_kit_id}:{$plugin_kit_line}\n" );
	}
}
$plugin_kit_errors = is_array( $plugin_kit_report ) && is_array( $plugin_kit_report['errors'] ?? null ) ? $plugin_kit_report['errors'] : array();
fwrite( STDOUT, str_repeat( "none:0\n", count( $plugin_kit_errors ) ) );
