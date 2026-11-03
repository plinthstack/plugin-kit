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

The kit brings PHPCS, PHPStan and their extensions, so a plugin needs only `"config": { "allow-plugins": { "dealerdirect/phpcodesniffer-composer-installer": true, "phpstan/extension-installer": true } }` in its `composer.json`. `testVersion` is required: PHPCompatibility stops with an internal error without it. Rules added after the include override the kit's; the kit sets no `<config>` values, since PHPCS would let them override the plugin's. For PHPCompatibility 10's PHP 8 checks, also require `"phpcompatibility/php-compatibility": "^10.0@alpha"`.

A plugin's `phpstan.neon.dist` includes the base config (`level: max`, WordPress and PHPUnit extensions, the WordPress test-suite stubs), then lists its own `paths`:

```neon
includes:
	- vendor/plinthstack/plugin-kit/phpstan/base.neon

parameters:
	paths:
		- plinthstack-demo.php
		- inc
```

Its own `scanFiles` add to the kit's. Run it with `vendor/bin/phpstan analyse --memory-limit=1G`; the WordPress stubs need more than PHP's default 128M.

## Development

`composer test` runs PHPCS (`phpcs.xml`) and PHPStan (`phpstan.neon.dist`) on the kit's own PHP, then `plugin-kit validate` against `tests/fixtures/` and PHPCS and PHPStan against the sample plugins in `tests/phpcs/` and `tests/phpstan/`. Run `vendor/bin/phpcs` or `vendor/bin/phpstan analyse --memory-limit=1G` to check the kit alone. CI also runs actionlint on `.github/workflows/`. Run it locally with `docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:1.7.12`. Dependabot checks the Composer and GitHub Actions dependencies (npm once #5 adds them) weekly and opens a PR per update; the actionlint image is bumped by hand, since Dependabot skips `docker://` references.
