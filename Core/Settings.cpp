#include "Settings.hpp"
#include <cstdint>
#include <limits>

namespace phk {
int normalizeTTL(int value, int unit) noexcept {
    if (value <= 0 || unit < 0 || unit > 2) return 0;
    constexpr std::int64_t factors[] = {1, 3600, 86400};
    const auto seconds = static_cast<std::int64_t>(value) * factors[unit];
    return seconds > kMaxTTLSeconds ? kMaxTTLSeconds : static_cast<int>(seconds);
}
std::string version() noexcept { return "1.0.0"; }
}
