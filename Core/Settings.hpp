#pragma once
#include <cstdint>
#include <string>

namespace phk {
inline constexpr int kMaxTTLSeconds = 30 * 24 * 60 * 60;
inline constexpr int kSchemaVersion = 1;
// Unit: 0 = seconds, 1 = hours, 2 = days. Negative and unknown values are rejected.
int normalizeTTL(int value, int unit) noexcept;
std::string version() noexcept;
}
