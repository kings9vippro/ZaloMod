#pragma once
#include <cstdint>
#include <string>

namespace phk {
inline constexpr int kMaxTTLSeconds = 30 * 24 * 60 * 60;
inline constexpr int kSchemaVersion = 2;

enum class TTLUnit : std::uint8_t { seconds = 0, hours = 1, days = 2 };

// Saturating conversion. Invalid units and nonpositive values produce zero.
int normalizeTTL(int value, TTLUnit unit) noexcept;
int normalizeTTL(int value, int unit) noexcept;

// Pure, deterministic tab movement logic independent of UIKit/SwiftUI.
// Invalid count returns zero. Out-of-range indices are clamped.
// Tiny drags and non-finite values do not change the selection.
int nextTabIndex(int currentIndex, int tabCount, double horizontalDragPoints) noexcept;
std::string version();
}
