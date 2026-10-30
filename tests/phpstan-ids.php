<?php
/**
 * Prints identifier:line for each error in PHPStan's JSON output on stdin.
 *
 * @package PlinthStack\PluginKit
 */

$plugin_kit_report = json_decode( (string) stream_get_contents( STDIN ), true );
foreach ( $plugin_kit_report['files'] ?? array() as $plugin_kit_file ) {
	foreach ( $plugin_kit_file['messages'] as $plugin_kit_message ) {
		echo $plugin_kit_message['identifier'], ':', $plugin_kit_message['line'], "\n";
	}
}
