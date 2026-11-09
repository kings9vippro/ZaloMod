#include "Settings.hpp"
#include <algorithm>
#include <cmath>
#include <cstdint>

namespace phk {
namespace {
constexpr std::int64_t multiplier(TTLUnit unit) noexcept {
    switch (unit) {
    case TTLUnit::seconds: return 1;
    case TTLUnit::hours: return 3600;
    case TTLUnit::days: return 86400;
    }
    return 0;
}
constexpr double kSwipeThreshold = 43.0;
}

int normalizeTTL(int value, TTLUnit unit) noexcept {
    if (value <= 0) return 0;
    const auto scale = multiplier(unit);
    if (scale == 0) return 0;
    // Test before multiplication: prevents overflow even if caller passes INT_MAX.
    if (static_cast<std::int64_t>(value) >=
        static_cast<std::int64_t>(kMaxTTLSeconds) / scale)
        return kMaxTTLSeconds;
    return static_cast<int>(static_cast<std::int64_t>(value) * scale);
}

int normalizeTTL(int value, int unit) noexcept {
    if (unit < 0 || unit > 2) return 0;
    return normalizeTTL(value, static_cast<TTLUnit>(unit));
}

int nextTabIndex(int currentIndex, int tabCount, double horizontalDragPoints) noexcept {
    if (tabCount <= 0) return 0;
    // Explicit boundary handling avoids overflow in currentIndex +/- 1.
    const int current = std::clamp(currentIndex, 0, tabCount - 1);
    if (!std::isfinite(horizontalDragPoints) ||
        std::fabs(horizontalDragPoints) < kSwipeThreshold)
        return current;
    if (horizontalDragPoints < 0) return current == tabCount - 1 ? current : current + 1;
    return current == 0 ? current : current - 1;
}

std::string version() { return "2.0.0"; }
}
