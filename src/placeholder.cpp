// Keeps merlion_node_exporter_lib non-empty until the first real translation
// unit lands. Delete this file in the PR that adds src/encoding.cpp.

namespace merlion::node_exporter::detail {
inline constexpr int kScaffoldSentinel = 0;
}
