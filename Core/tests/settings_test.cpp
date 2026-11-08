#include "../Settings.hpp"
#include <cassert>
int main() {
    assert(phk::normalizeTTL(-1, 0) == 0);
    assert(phk::normalizeTTL(0, 0) == 0);
    assert(phk::normalizeTTL(30, 0) == 30);
    assert(phk::normalizeTTL(2, 1) == 7200);
    assert(phk::normalizeTTL(2, 2) == 172800);
    assert(phk::normalizeTTL(99999999, 2) == phk::kMaxTTLSeconds);
    assert(phk::normalizeTTL(4, 3) == 0);
    assert(phk::version() == "1.0.0");
}
