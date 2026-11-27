# shellcheck shell=bash
# Sourced by the npm test suites: moves to the repo root and reports each check.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
fail=0

# Prints "ok" or "FAIL" for a check name from the exit status of the check.
report() {
	if [ "$2" -eq 0 ]; then
		echo "ok   $1"
	else
		echo "FAIL $1"
		fail=1
	fi
}

# Prints a new, empty temporary folder's real path; a failed mktemp would leave it empty, and cd "" stays in the repo.
temp_dir() {
	local dir
	dir=$(mktemp -d) && [ -d "$dir" ] && cd "$dir" && pwd -P
}

# Prints a plugin-shaped temporary folder holding src/ plus build/ and vendor/ at the root and nested.
plugin_dir() {
	local dir
	dir=$(temp_dir) || return 1
	mkdir -p "$dir/src" "$dir/build" "$dir/vendor/demo" "$dir/blocks/demo/build"
	echo "$dir"
}

# Exits non-zero when any reported check failed.
finish() {
	exit "$fail"
}
