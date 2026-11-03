#!/usr/bin/env bash
# Runs bin/plugin-kit on every fixture, and PHPCS and PHPStan on the sample plugins, and checks the results.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

# Runs bin/plugin-kit with the given arguments and compares its exit code and whole output.
check() {
	local status=$1 expected=$2 out got
	shift 2
	out=$(bin/plugin-kit "$@" 2>&1)
	got=$?
	if [ "$got" -ne "$status" ] || [ "$out" != "$expected" ]; then
		echo "FAIL plugin-kit $*: exit $got, expected $status and [$expected]"
		echo "$out"
		fail=1
	else
		echo "ok   plugin-kit $*"
	fi
}

check 2 'Usage: plugin-kit validate [path]'
check 0 'tests/fixtures/valid.json is valid' validate tests/fixtures/valid.json
check 1 'slug: The property slug is required' validate tests/fixtures/invalid-missing.json
check 1 'requires_php: Double value found, but a string is required' validate tests/fixtures/invalid-type.json
check 1 'tier: Does not have a value in the enumeration ["free","premium"]' validate tests/fixtures/invalid-tier.json
check 1 '(root): NULL value found, but an object is required' validate tests/fixtures/invalid-root.json

# Runs PHPCS with a sample config and compares the sniff codes it reports.
sniffs() {
	local out status got
	out=$(vendor/bin/phpcs -q -s --no-colors --report=emacs --standard="tests/phpcs/$1" "tests/phpcs/$2")
	status=$?
	got=$(echo "$out" | sed -n 's/.*(\(.*\))$/\1/p' | sort | tr '\n' ' ')
	if [ "$status" -gt 2 ] || [ "$got" != "$3" ]; then
		echo "FAIL phpcs $1 $2: exit $status, got [$got], expected [$3]"
		echo "$out"
		fail=1
	else
		echo "ok   phpcs $1 $2"
	fi
}

sniffs phpcs.xml clean.php ''
sniffs phpcs.xml violation.php 'PHPCompatibility.FunctionUse.RemovedFunctions.eachDeprecated WordPress.NamingConventions.PrefixAllGlobals.NonPrefixedFunctionFound WordPress.PHP.YodaConditions.NotYoda WordPress.WP.AlternativeFunctions.file_system_operations_readfile WordPressVIPMinimum.Functions.StripTags.StripTagsOneParameter '
sniffs override.xml violation.php 'PHPCompatibility.FunctionUse.RemovedFunctions.eachDeprecated WordPress.NamingConventions.PrefixAllGlobals.NonPrefixedFunctionFound WordPress.PHP.YodaConditions.NotYoda WordPressVIPMinimum.Functions.StripTags.StripTagsOneParameter '

# Runs PHPStan with the sample config and compares the identifier:line pairs it reports.
analyse() {
	local out status got
	out=$(vendor/bin/phpstan analyse --memory-limit=1G --no-progress --error-format=json -c tests/phpstan/phpstan.neon "tests/phpstan/$1" 2>/dev/null)
	status=$?
	got=$(echo "$out" | php tests/phpstan-ids.php | sort | tr '\n' ' ')
	if { [ -z "$2" ] && [ "$status" -ne 0 ]; } || [ "$got" != "$2" ]; then
		echo "FAIL phpstan $1: exit $status, got [$got], expected [$2]"
		echo "$out"
		fail=1
	else
		echo "ok   phpstan $1"
	fi
}

analyse clean.php ''
analyse violation.php 'argument.type:20 property.nonObject:12 '

# PHPStan reports some errors, such as an unmatched ignore pattern, outside any file.
if [ "$(printf '{"files":[],"errors":["x"]}' | php tests/phpstan-ids.php)" = 'none:0' ]; then
	echo "ok   phpstan-ids.php top-level errors"
else
	echo "FAIL phpstan-ids.php drops top-level errors"
	fail=1
fi

exit $fail
