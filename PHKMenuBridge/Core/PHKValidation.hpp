#pragma once
#include <cstdint>
#include <string>
namespace phk {
// Pure C++17 input validation. No Zalo SDK dependencies.
bool validTTL(const std::string &digits, int unit, std::int64_t *milliseconds) noexcept;
bool validPrefix(const std::string &prefix) noexcept;
}
