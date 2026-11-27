# plugin-kit
Shared tooling and scaffold for PlinthStack WordPress plugins

## Requirements

- PHP 8.1 or later, and Node 22.22.2+ or 24.15+ for the npm package.
- The kit brings PHPCS, PHPStan and their extensions, so a plugin requires none of them itself (PHPCompatibility 10 is an opt-in; see PHPCS below). Its `composer.json` needs this `config`:

  ```json
  "config": {
  	"allow-plugins": {
  		"dealerdirect/phpcodesniffer-composer-installer": true,
  		"phpstan/extension-installer": true
  	}
  }
  ```

## Usage

### Validate plugin-kit.json

`vendor/bin/plugin-kit validate [path]` checks a plugin's `plugin-kit.json` (default `./plugin-kit.json`) against the schema and exits 1 with one line per problem.

Add `"$schema": "./vendor/plinthstack/plugin-kit/schema/plugin-kit.schema.json"` to the file for editor hints.

### PHPCS

A plugin's `phpcs.xml` includes the shared ruleset, then adds its own values:

```xml
<file>.</file>
<arg name="basepath" value="."/>
<rule ref="vendor/plinthstack/plugin-kit/phpcs/ruleset.xml"/>
<config name="text_domain" value="plinthstack-demo"/>
<config name="testVersion" value="8.1-"/>
```

- `testVersion` is required: PHPCompatibility stops with an internal error without it.
- Rules added after the include override the kit's.
- The kit sets no `<config>` values, since PHPCS would let them override the plugin's.
- For PHPCompatibility 10's PHP 8 checks, also require `"phpcompatibility/php-compatibility": "^10.0@alpha"`.

#### Complexity limits

The ruleset limits each function's cyclomatic complexity and nesting:

| Sniff | Warning above | Warning property | Error above | Error property |
|---|---|---|---|---|
| `Generic.Metrics.CyclomaticComplexity` | 10 | `complexity` | 20 | `absoluteComplexity` |
| `Generic.Metrics.NestingLevel` | 5 | `nestingLevel` | 10 | `absoluteNestingLevel` |

`phpcs` exits non-zero on warnings and errors alike, so both fail a plugin's `phpcs` run. A plugin changes a limit with a `<property>` on the sniff, after the include.

### PHPStan

A plugin's `phpstan.neon.dist` includes the base config (`level: max` and the WordPress test-suite stubs), then lists its own `paths`:

```neon
includes:
	- vendor/plinthstack/plugin-kit/phpstan/base.neon

parameters:
	paths:
		- plinthstack-demo.php
		- inc
```

- `phpstan/extension-installer` loads the WordPress and PHPUnit extensions.
- A plugin's own `scanFiles` add to the kit's.
- Run it with `vendor/bin/phpstan analyse --memory-limit=1G`; the WordPress stubs need more than PHP's default 128M.

### Prettier

The npm package brings Prettier (the `wp-prettier` fork, as `@wordpress/scripts` uses) and the WordPress config. A plugin's `.prettierrc.js` re-exports it:

```js
module.exports = require( '@plinthstack/plugin-kit/prettier' );
```

In a plugin whose `package.json` sets `"type": "module"`, name the file `.prettierrc.cjs`, or Prettier and ESLint stop with `module is not defined in ES module scope`.

If the plugin lists its own `prettier`, alias it to `wp-prettier` with the same range as the kit's `prettier` dependency. Otherwise npm dedupes the kit's fork onto upstream Prettier, which warns `Ignored unknown option { parenSpacing: … }` and formats without paren spacing.

To change an option, spread the kit's config first. A plugin that sets its own `overrides` spreads the kit's `overrides` into it too, or stylesheets lose their settings:

```js
module.exports = {
	...require( '@plinthstack/plugin-kit/prettier' ),
	printWidth: 100,
};
```

### ESLint

The npm package brings ESLint 9 and WordPress's recommended flat config. A plugin's `eslint.config.mjs` spreads it, then adds its own rules:

```js
import kit from '@plinthstack/plugin-kit/eslint';

export default [ ...kit, { rules: { 'no-console': 'off' } } ];
```

- It runs Prettier as the `prettier/prettier` rule and turns off the style rules Prettier owns.
- That rule reads the Prettier config once, from the folder ESLint runs in, so Prettier `overrides` for JS files do not reach it. Run ESLint from the plugin root.
- It skips `build/` and `vendor/` folders at any depth.
- ESLint stays on 9 until the plugins inside `@wordpress/eslint-plugin` accept 10; with 10, npm installs a second ESLint and plugins still run 9.

### Stylelint

The npm package brings stylelint 17 and WordPress's stylelint config, with its SCSS rules for `.scss` files. A plugin's `.stylelintrc.json` extends it, then adds its own rules:

```json
{
	"extends": "@plinthstack/plugin-kit/stylelint",
	"rules": { "color-named": null }
}
```

- `stylelint --fix` output passes the kit's Prettier check, so the two never undo each other.
- It skips `build/` and `vendor/` folders at any depth, so a plugin inside a folder named `build` or `vendor` is skipped entirely.
- A plugin that sets its own `ignoreFiles` replaces the kit's, so it lists `/**/build/**` and `/**/vendor/**` again, with the leading slash.
- Stylelint stays on 17, the version `@wordpress/stylelint-config` requires.

## Development

### Tests

`composer test` runs, in order:

1. PHPCS (`phpcs.xml`) and PHPStan (`phpstan.neon.dist`) on the kit's own PHP.
2. `plugin-kit` with no arguments (usage message) and `plugin-kit validate` against `tests/fixtures/`.
3. PHPCS and PHPStan against the sample plugins in `tests/phpcs/` and `tests/phpstan/`.
4. A self-test of `tests/phpstan-ids.php` for errors PHPStan reports outside any file.

Run `vendor/bin/phpcs` or `vendor/bin/phpstan analyse --memory-limit=1G` to check the kit alone.

`npm test` runs, in order:

1. Prettier on the samples in `tests/prettier/`, with the kit's config and a plugin override, compared with each expected file.
2. ESLint on the samples in `tests/eslint/`, with the kit's config and a plugin override, compared with each expected list of rule IDs, then on a plugin-shaped folder to check it skips `build/` and `vendor/`.
3. Stylelint on the samples in `tests/stylelint/` the same way, then on Prettier-formatted stylesheets to check its fixes leave Prettier nothing to change.

All three suites run even when one fails.

### CI

| Job | Checks |
|---|---|
| `php` | `composer validate --strict`, then `composer test` |
| `npm` | `npm ci`, `npm test`, then the npm tarball holds exactly the paths in the job's expected list |
| `actionlint` | `.github/workflows/`; run it locally with `docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:1.7.12` |

A new shared config goes in `package.json` `files` and `exports`, and, with every file path it packs, in the `npm` job's expected list.

### Dependencies

- Dependabot checks the Composer, npm and GitHub Actions dependencies weekly and opens a PR per update.
- The actionlint image is bumped by hand, since Dependabot skips `docker://` references.
- Dependabot skips ESLint, stylelint and stylelint-scss major versions; see ESLint and Stylelint above.
