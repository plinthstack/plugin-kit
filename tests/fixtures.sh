#!/usr/bin/env bash
# Runs bin/plugin-kit validate on every fixture, and PHPCS and PHPStan on the sample plugins, and checks the results.
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

check() {
	local out got
	out=$(bin/plugin-kit validate "$1" 2>&1)
	got=$?
	if [ "$got" -ne "$2" ] || { [ -n "${3:-}" ] && [[ "$out" != "$3:"* ]]; }; then
		echo "FAIL $1: exit $got, expected $2${3:+ naming $3}"
		echo "$out"
		fail=1
	else
		echo "ok   $1"
	fi
}

check tests/fixtures/valid.json 0
check tests/fixtures/invalid-missing.json 1 slug
check tests/fixtures/invalid-type.json 1 requires_php
check tests/fixtures/invalid-tier.json 1 tier

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
	out=$(vendor/bin/phpstan analyse --memory-limit=1G --no-progress --error-format=raw -c tests/phpstan/phpstan.neon "tests/phpstan/$1" 2>&1)
	status=$?
	got=$(echo "$out" | sed -n 's/^[^:]*:\([0-9]*\):.*\[identifier=\(.*\)\]$/\2:\1/p' | sort | tr '\n' ' ')
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

exit $fail
