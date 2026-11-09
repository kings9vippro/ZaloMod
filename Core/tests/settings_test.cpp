#include "../Settings.hpp"
#include <cassert>
#include <cmath>
#include <limits>

int main() {
    using phk::normalizeTTL;
    assert(normalizeTTL(-1, 0) == 0);
    assert(normalizeTTL(0, 0) == 0);
    assert(normalizeTTL(30, 0) == 30);
    assert(normalizeTTL(2, 1) == 7200);
    assert(normalizeTTL(2, 2) == 172800);
    assert(normalizeTTL(30, 2) == phk::kMaxTTLSeconds);
    assert(normalizeTTL(31, 2) == phk::kMaxTTLSeconds);
    assert(normalizeTTL(720, 1) == phk::kMaxTTLSeconds);
    assert(normalizeTTL(std::numeric_limits<int>::max(), 2) == phk::kMaxTTLSeconds);
    assert(normalizeTTL(4, -1) == 0);
    assert(normalizeTTL(4, 3) == 0);
    assert(normalizeTTL(100, static_cast<phk::TTLUnit>(50)) == 0);
    assert(phk::kSchemaVersion == 2);
    using phk::nextTabIndex;
    assert(nextTabIndex(0, 5, -80) == 1);
    assert(nextTabIndex(1, 5, 80) == 0);
    assert(nextTabIndex(4, 5, -500) == 4);
    assert(nextTabIndex(0, 5, 500) == 0);
    assert(nextTabIndex(2, 5, -42.9) == 2);
    assert(nextTabIndex(2, 5, -43.0) == 3);
    assert(nextTabIndex(-20, 5, 0) == 0);
    assert(nextTabIndex(999, 5, 0) == 4);
    assert(nextTabIndex(5, 0, 120) == 0);
    assert(nextTabIndex(2, 5, std::numeric_limits<double>::quiet_NaN()) == 2);
    assert(nextTabIndex(2, 5, std::numeric_limits<double>::infinity()) == 2);
    assert(phk::version() == "2.0.0");
}
