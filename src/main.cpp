// Entry point — replaced with the real CLI + server wiring once the core
// modules land (see docs/DESIGN.md §7 Implementation Plan).
//
// Today this binary just reports its version and exits, so the scaffold
// can be smoke-tested in CI before any collectors exist.

#include <cstdio>
#include <string_view>

#include "merlion_node_exporter/version.hpp"

namespace mne = merlion::node_exporter;

int main(int argc, char** argv) {
    for (int i = 1; i < argc; ++i) {
        std::string_view arg{argv[i]};
        if (arg == "--version" || arg == "-V") {
            std::printf("merlion-node-exporter %s\n", mne::version_string);
            return 0;
        }
    }
    std::printf(
        "merlion-node-exporter %s — scaffold build, no collectors wired up.\n"
        "See https://github.com/MerlionOS/merlion-node-exporter-cpp/blob/main/docs/DESIGN.md\n",
        mne::version_string
    );
    return 0;
}
