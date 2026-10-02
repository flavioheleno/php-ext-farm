# Shared build exclusion rules and matrix generation.
#
# Included as a jq module by scripts/check-exclusion.sh and by the
# build/tests workflows:
#
#   jq -n -L scripts 'include "exclusions"; ...'
#
# Keeping these definitions in one file means a change to the matching rules
# reaches the build matrix and the per-build check at the same time.

# Convert a glob pattern (only * is special) to a regex and test $value.
def wildcard_match($pattern; $value):
  ($pattern | gsub("\\."; "\\.") | gsub("\\*"; ".*")) as $re
  | $value | test("^" + $re + "$");

# Platform-level exclusions, from os-versions.json (os is implicit).
def is_os_excluded($os_versions; $platform; $osv; $arch):
  ($os_versions[$platform].exclude // [])
  | any(wildcard_match(.version; $osv) and wildcard_match(.arch; $arch));

# Extension-level exclusions, from extensions.json (os is required).
def is_ext_excluded($extensions; $ext; $platform; $osv; $arch):
  ($extensions.extensions[$ext].exclude // [])
  | any(wildcard_match(.os; $platform)
        and wildcard_match(.version; $osv)
        and wildcard_match(.arch; $arch));

def is_excluded($os_versions; $extensions; $ext; $platform; $osv; $arch):
  is_os_excluded($os_versions; $platform; $osv; $arch)
  or is_ext_excluded($extensions; $ext; $platform; $osv; $arch);

# "excluded_by_platform", "excluded_by_extension" or "allowed".
def exclusion_reason($os_versions; $extensions; $ext; $platform; $osv; $arch):
  if is_os_excluded($os_versions; $platform; $osv; $arch) then
    "excluded_by_platform"
  elif is_ext_excluded($extensions; $ext; $platform; $osv; $arch) then
    "excluded_by_extension"
  else
    "allowed"
  end;

# GitHub Actions build matrix with excluded combinations filtered out.
# $php_vers, $platforms and $archs are comma separated lists or "all".
def build_matrix($php_versions; $os_versions; $extensions; $ext; $php_vers; $platforms; $archs):
  (if $php_vers == "all" then ($php_versions | keys) else ($php_vers | split(",")) end) as $php_list
  | (if $archs == "all" then $extensions.architectures else ($archs | split(",")) end) as $architectures
  | (if $platforms == "all" then ["alpine", "debian"] else ($platforms | split(",")) end) as $platform_list
  | {include: [
      $platform_list[] as $platform
      | $os_versions[$platform].versions[]? as $osv
      | $php_list[] as $php
      | $architectures[] as $arch
      | select(is_excluded($os_versions; $extensions; $ext; $platform; $osv; $arch) | not)
      | {php_version: $php, platform: $platform, platform_version: $osv, arch: $arch}
    ]};
