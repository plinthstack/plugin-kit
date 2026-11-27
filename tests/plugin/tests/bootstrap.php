<?php
/**
 * PHPUnit bootstrap, run inside wp-env's cli container.
 *
 * @package PlinthStack\Demo
 */

$plinthstack_demo_tests_dir = getenv( 'WP_TESTS_DIR' );

if ( ! is_string( $plinthstack_demo_tests_dir ) || ! file_exists( $plinthstack_demo_tests_dir . '/includes/functions.php' ) ) {
	echo 'WordPress test suite not found. Run the tests in the container: npm run test:php', PHP_EOL;
	exit( 1 );
}

require_once dirname( __DIR__ ) . '/vendor/autoload.php';
require_once $plinthstack_demo_tests_dir . '/includes/functions.php';

tests_add_filter(
	'muplugins_loaded',
	static function () {
		require dirname( __DIR__ ) . '/plinthstack-demo.php';
	}
);

require $plinthstack_demo_tests_dir . '/includes/bootstrap.php';
