<?php
/**
 * Breaks one rule from each standard the kit's ruleset includes, and one whose severity it raises.
 *
 * @package PlinthStack\Demo
 */

/**
 * Reads a file without the plugin's prefix.
 *
 * @param array $plinthstack_demo_list Items.
 */
function demo_read( $plinthstack_demo_list ) {
	readfile( __DIR__ . '/clean.php' );
	if ( $plinthstack_demo_list === array() ) {
		return strip_tags( '<b>none</b>' );
	}
	return each( $plinthstack_demo_list );
}
