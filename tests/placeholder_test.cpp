// Smoke test asserting the test runner itself works before any collectors
// have a test of their own. Delete in the PR that adds the first real test.

#include <catch2/catch_test_macros.hpp>

TEST_CASE("scaffold smoke test", "[scaffold]") {
    REQUIRE(1 + 1 == 2);
}
