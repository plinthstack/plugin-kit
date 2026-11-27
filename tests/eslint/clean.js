/**
 * Returns the PlinthStack demo greeting for a name.
 *
 * @param {string} name Visitor name.
 * @return {string} Greeting.
 */
export function plinthstackDemoGreeting( name ) {
	return name === '' ? 'Hello' : `Hello, ${ name }`;
}
