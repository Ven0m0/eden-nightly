#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -e; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C

command -v llvm-profdata &>/dev/null || exit 1

echo "-- Generating merged PGO profile data..."

OUTPUT="./eden.profdata"
WEIGHTS=(${1:-5} ${2:-3} ${3:-1})

# extract and merge profraw files from each .7z archive
for archive in ./*.7z; do
    version=$(basename "$archive" .7z)
    temp=$(mktemp -d)
    7z x "$archive" -o"$temp" -y &>/dev/null
    echo "-- Merging profraw files for version: $version"
    llvm-profdata merge "$temp"/*.profraw -o "$temp/$version.profdata" 2>/dev/null || {
      # windows llvm can't handle zlib compressed profraw files
      echo "   WARNING: Non-compatible profraw file: $version, use premerged profdata instead."
      rm -rf "$temp"
      continue
    }
    mv -fv "$temp/$version.profdata" ./
    rm -rf "$temp"
done

# validate profile version for each profdata file in case we update llvm version later
declare -A version_map
latest_version=""
versions=()

for file in ./*.profdata; do
    version=$(basename "$file" .profdata)
    echo "-- Full profile version output for $version:"
    llvm-profdata show --profile-version "$file"
    profile_version=$(llvm-profdata show --profile-version "$file" | tail -1 | grep -o '[0-9]\+$')
    if [ -n "$profile_version" ]; then
        # update latest version
        if [ -z "$latest_version" ] || [ "$profile_version" -gt "$latest_version" ]; then
            latest_version="$profile_version"
        fi
        version_map["$version"]="$profile_version"
        versions+=("$version")
    fi
done
echo "-- Latest Profile Version: $latest_version"

# remove outdated profdata files
for version in "${versions[@]}"; do
    profile_version="${version_map[$version]}"
    if [ "$profile_version" -lt "$latest_version" ]; then
        echo "-- $version.profdata: Profile version is outdated ($profile_version vs $latest_version), removing"
        rm -f "./$version.profdata"
    fi
done

# collect version names with matching profile version and sort them in descending order
IFS=$'\n' sorted_versions=($(sort -rn <<< "${versions[*]}"))
unset IFS
echo "-- Valid version sequence for merging: ${sorted_versions[@]}"

# merge profdata files with weights
echo "-- Merging profdata files..."
merge_args=()
for i in "${!sorted_versions[@]}"; do
    version="${sorted_versions[$i]}"
    weight="${WEIGHTS[$i]:-${WEIGHTS[-1]}}"
    merge_args+=( "--weighted-input=$weight,./$version.profdata" )
    echo "  $version.profdata -> weight: $weight"
done
llvm-profdata merge "${merge_args[@]}" -o "$OUTPUT"

echo "-- Final merged profdata: $OUTPUT"
