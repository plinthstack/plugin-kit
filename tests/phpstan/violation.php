<?php
/**
 * Fails at level max, and only with the WordPress extension's return types.
 *
 * @package PlinthStack\Demo
 */

/**
 * Returns a post title.
 */
function plinthstack_demo_title(): string {
	return get_post( 1 )->post_title;
}

/**
 * Returns a callback that measures a value it cannot know the type of.
 */
function plinthstack_demo_measure(): Closure {
	return function ( $plinthstack_demo_value ): int {
		return strlen( $plinthstack_demo_value );
	};
}
