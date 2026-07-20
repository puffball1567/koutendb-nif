# Shared build settings.
# ARC keeps the codec runtime small and predictable for C ABI consumers.
# The implementation avoids reference cycles; cross-structure links should use
# ids or indexes rather than owning back-references.
switch("mm", "arc")

# Local development expects nifkit as a sibling repository:
#
#   oss/
#     nifkit/
#     koutendb-nif/
#
# After nifkit is accepted into the Nimble package list, this can be replaced
# by a normal `requires "nifkit >= 0.1.0"` dependency in koutendb_nif.nimble.
switch("path", "src")
switch("path", "../nifkit/src")
switch("path", "nifkit/src")
