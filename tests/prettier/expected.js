const plinthstackDemo = { items: [ 1, 2, 3 ], label: 'Demo' };
function plinthstackDemoTotal( items ) {
	return items.reduce( ( sum, item ) => sum + item, 0 );
}
const plinthstackDemoDoubled = plinthstackDemo.items.map(
	( item ) => item * 2
);
const plinthstackDemoSettings = {
	title: 'PlinthStack Demo settings',
	description: 'Shown on the settings screen',
};
const plinthstackDemoButton = (
	<button
		className="plinthstack-demo-button"
		onClick={ plinthstackDemoTotal }
		disabled
	>
		Save
	</button>
);
function plinthstackDemoLabel() {
	return (
		plinthstackDemoSettings.title + ' for ' + plinthstackDemo.label + '!!'
	);
}
