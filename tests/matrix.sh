#!/usr/bin/env bash
# Runs tests.yml's matrix step with fixed versions and inputs, and compares the rows it builds.
set -u
# shellcheck source=tests/lib.sh
. "$(dirname "$0")/lib.sh"

if ! build=$(yq -e '.jobs.resolve.steps[] | select(.name == "Build the matrix") | .run' .github/workflows/tests.yml); then
	echo 'FAIL tests.yml matrix step not found'
	exit 1
fi

# Builds the matrix with the floor at WP 6.7.12 / PHP 8.1 and latest at WP 7.1.5 / PHP 8.5 unless overridden,
# and prints each row as "wp php multisite experimental", sorted.
rows() {
	local dir status
	dir=$(temp_dir) || return 1
	(
		export GITHUB_OUTPUT=$dir/output FLOOR_WP=${FLOOR_WP:-6.7.12} FLOOR_PHP=8.1 LATEST_WP=7.1.5 LATEST_PHP=8.5
		export FULL=${FULL:-false} MULTISITE=${MULTISITE:-true} INCLUDE=${INCLUDE:-[]} EXCLUDE=${EXCLUDE:-[]}
		bash -eo pipefail -c "$build" >/dev/null &&
			sed -n 's/^matrix=//p' "$GITHUB_OUTPUT" | jq -r '.include[] | "\(.wp) \(.php) \(.multisite) \(.experimental)"' | LC_ALL=C sort
	)
	status=$?
	rm -rf "$dir"
	return $status
}

# Compares the rows with the expected lines, given one per argument.
expect() {
	local got
	got=$(rows) || return 1
	diff <(printf '%s\n' "$@" | LC_ALL=C sort) <(echo "$got")
}

expect '6.7.12 8.1 false false' '7.1.5 8.5 false false' '7.1.5 8.5 true false'
report "matrix runs the floor, the latest and multisite by default" $?
MULTISITE=false expect '6.7.12 8.1 false false' '7.1.5 8.5 false false'
report "matrix drops multisite when turned off" $?
FULL=true expect '6.7.12 8.1 false false' '6.7.12 8.5 false false' '7.1.5 8.1 false false' '7.1.5 8.5 false false' '7.1.5 8.5 true false' 'trunk 8.5 false true'
report "matrix adds the corners and an experimental trunk with full" $?
INCLUDE='[{"wp": "6.9", "php": "latest"}, {"wp": "floor", "php": "8.3", "multisite": true}]' expect '6.7.12 8.1 false false' '6.7.12 8.3 true false' '6.9 8.5 false false' '7.1.5 8.5 false false' '7.1.5 8.5 true false'
report "matrix adds included rows, resolving floor and latest" $?
INCLUDE='[{"wp": "trunk", "php": "8.3"}, {"wp": "6.9", "php": "8.3", "experimental": true}]' MULTISITE=false expect '6.7.12 8.1 false false' '6.9 8.3 false false' '7.1.5 8.5 false false' 'trunk 8.3 false true'
report "matrix lets only trunk rows fail" $?
EXCLUDE='[{"wp": "floor", "php": "floor"}, {"wp": "latest", "php": "latest", "multisite": true}]' expect '7.1.5 8.5 false false'
report "matrix drops excluded rows, matching multisite" $?
FLOOR_WP=7.1.5 MULTISITE=false expect '7.1.5 8.1 false false' '7.1.5 8.5 false false'
report "matrix keeps distinct PHP rows when the floor WordPress is the latest" $?
FULL=true FLOOR_WP=7.1.5 MULTISITE=false expect '7.1.5 8.1 false false' '7.1.5 8.5 false false' 'trunk 8.5 false true'
report "matrix runs each duplicate row once" $?
! EXCLUDE='[{"wp": "floor", "php": "floor"}, {"wp": "latest", "php": "latest"}]' MULTISITE=false rows >/dev/null 2>&1
report "matrix fails when every row is excluded" $?
! INCLUDE='not json' rows >/dev/null 2>&1
report "matrix fails on an include that is not JSON" $?

finish
