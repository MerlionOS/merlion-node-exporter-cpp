# merlion-node-exporter-cpp

Modern C++23 reimplementation of the Prometheus
[`node_exporter`](https://github.com/prometheus/node_exporter) — hardware
and OS metrics exposed by \*NIX kernels, in a single statically-linked
binary.

This is the C++ sibling of
[`merlion-node-exporter-rs`](https://github.com/MerlionOS/merlion-node-exporter-rs),
following the same dual-language pattern as
[`merlion-tsdb-cpp`](https://github.com/MerlionOS/merlion-tsdb-cpp) /
[`merlion-tsdb-rs`](https://github.com/MerlionOS/merlion-tsdb-rs). Both
exporters expose the **same Prometheus text-format on `/metrics`** and
use **byte-identical metric names**, so they are drop-in replacements
for each other — and for upstream `node_exporter` — from a scrape /
dashboard / alerting standpoint.

The installed binary is named `merlion-node-exporter` (no language
suffix) — pick the implementation that matches your build toolchain;
operators run the same command either way.

> **Status — design-stage.** The architecture, dependency choices, file
> layout, and interface signatures are pinned in
> [`docs/DESIGN.md`](docs/DESIGN.md). The CMake scaffold builds an empty
> binary today; implementation is tracked in the
> [Implementation Plan](docs/DESIGN.md#implementation-plan).

## Why a C++ version too?

`merlion-node-exporter-rs` is the primary implementation today. The C++
sibling exists for the same reasons as `merlion-tsdb-cpp`:

1. **Toolchain reach.** Some deployment environments standardise on a
   C++ toolchain (LLVM-only fleets, vendored CMake superbuilds, embedded
   targets) and a parallel C++ implementation lets those environments
   adopt Merlion without dragging in a Rust toolchain.
2. **Cross-checking.** Two independent implementations of the same wire
   protocol catch ambiguity bugs in the spec itself.
3. **Design discipline.** Forcing every collector to express the same
   metric in two languages keeps the metric-naming contract honest.

## Tech stack

| Concern | Choice | Why |
| --- | --- | --- |
| Language | C++23 | `std::expected`, `std::format`, designated init, modules-ready |
| Compiler | Clang 18+ (Homebrew LLVM on macOS) | Matches the rest of MerlionOS |
| Build | CMake 3.28+ | `FetchContent` makes deps trivial |
| HTTP | [`cpp-httplib`](https://github.com/yhirose/cpp-httplib) | Header-only, blocking, perfect for per-scrape exporters |
| CLI | [`CLI11`](https://github.com/CLIUtils/CLI11) | Header-only, idiomatic |
| Logging | [`spdlog`](https://github.com/gabime/spdlog) | Mirrors the `tracing` setup in `-rs` |
| Tests | [`Catch2`](https://github.com/catchorg/Catch2) v3 | Fixture-friendly |
| Format | `clang-format` | Pinned config in `.clang-format` |

See [`docs/DESIGN.md`](docs/DESIGN.md) for the rationale on each choice
and for the full file/module breakdown.

## Quick start

```bash
brew install llvm cmake
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
./build/merlion-node-exporter --web.listen-address :9100
```

On macOS, point CMake at Homebrew LLVM explicitly if `cc`/`clang++` on
your `$PATH` is still Apple Clang:

```bash
export CC="$(brew --prefix llvm)/bin/clang"
export CXX="$(brew --prefix llvm)/bin/clang++"
```

## Roadmap

Mirrors [`merlion-node-exporter-rs`'s
roadmap](https://github.com/MerlionOS/merlion-node-exporter-rs#roadmap)
exactly — same Linux MVP scope (~15 collectors), same metric names,
same CLI flags. See [`docs/DESIGN.md#implementation-plan`](docs/DESIGN.md#implementation-plan)
for the ordering.

## Development

```bash
cmake -S . -B build -DMNE_BUILD_TESTS=ON
cmake --build build -j
ctest --test-dir build --output-on-failure
clang-format --dry-run --Werror $(git ls-files '*.cpp' '*.hpp')
```

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE). Metric
names and CLI flags follow upstream `node_exporter` for compatibility.
