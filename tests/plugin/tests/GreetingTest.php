<?php
/**
 * Tests the sample plugin inside WordPress.
 *
 * @package PlinthStack\Demo
 */

/**
 * Greeting and environment tests.
 */
class GreetingTest extends WP_UnitTestCase {

	/**
	 * The plugin's function runs through WordPress's translation API.
	 */
	public function test_greeting() {
		$this->assertSame( 'Hello', plinthstack_demo_greeting() );
	}

	/**
	 * The multisite row really runs on a network.
	 */
	public function test_multisite_matches_the_row() {
		$this->assertSame( '1' === getenv( 'WP_MULTISITE' ), is_multisite() );
	}
}
