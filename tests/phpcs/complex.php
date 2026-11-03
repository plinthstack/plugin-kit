<?php
/**
 * Goes past the default complexity and nesting limits and breaks no other rule.
 *
 * @package PlinthStack\Demo
 */

/**
 * Counts the matching levels of a nested list.
 *
 * @param array $items Items.
 * @return int
 */
function plinthstack_demo_depth( $items ) {
	$found = 0;
	foreach ( $items as $a ) {
		if ( is_array( $a ) ) {
			foreach ( $a as $b ) {
				if ( is_array( $b ) ) {
					foreach ( $b as $c ) {
						if ( is_array( $c ) ) {
							++$found;
						} elseif ( is_int( $c ) ) {
							$found += 2;
						}
					}
				} elseif ( is_string( $b ) ) {
					++$found;
				}
			}
		}
	}
	return $found > 0 ? $found : ( $items['fallback'] ?? 0 );
}
