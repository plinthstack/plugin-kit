# plugin-kit
Shared tooling and scaffold for PlinthStack WordPress plugins

Requires PHP 8.1 or later.

## Usage

`vendor/bin/plugin-kit validate [path]` checks a plugin's `plugin-kit.json` (default `./plugin-kit.json`) against the schema and exits 1 with one line per problem.

Add `"$schema": "./vendor/plinthstack/plugin-kit/schema/plugin-kit.schema.json"` to the file for editor hints.

A plugin's `phpcs.xml` includes the shared ruleset, then adds its own values:

```xml
<file>.</file>
<arg name="basepath" value="."/>
<rule ref="vendor/plinthstack/plugin-kit/phpcs/ruleset.xml"/>
<config name="text_domain" value="plinthstack-demo"/>
<config name="testVersion" value="8.1-"/>
```

The kit brings PHPCS and its standards, so a plugin needs only `"config": { "allow-plugins": { "dealerdirect/phpcodesniffer-composer-installer": true } }` in its `composer.json`. `testVersion` is required: PHPCompatibility stops with an internal error without it. Rules added after the include override the kit's; the kit sets no `<config>` values, since PHPCS would let them override the plugin's. For PHPCompatibility 10's PHP 8 checks, also require `"phpcompatibility/php-compatibility": "^10.0@alpha"`.

## Development

`composer test` runs `plugin-kit validate` against `tests/fixtures/` and PHPCS against the sample plugin in `tests/phpcs/`.
