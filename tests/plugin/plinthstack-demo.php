<?php
/**
 * Plugin Name: PlinthStack Demo
 * Description: Sample plugin the kit's CI runs its reusable workflows on.
 * Version:     1.0.0
 * Requires at least: 6.7
 * Requires PHP: 8.1
 * License:     GPL-2.0-or-later
 * Text Domain: plinthstack-demo
 *
 * @package PlinthStack\Demo
 */

defined( 'ABSPATH' ) || exit;

define( 'PLINTHSTACK_DEMO_VERSION', '1.0.0' );

/**
 * Returns a greeting.
 *
 * @return string
 */
function plinthstack_demo_greeting() {
	return __( 'Hello', 'plinthstack-demo' );
}
