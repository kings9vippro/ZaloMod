#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace phk {
enum class Setting : std::uint8_t {
    haptics = 0, reducedMotion, compactLayout, softBackground, rememberSettings, count
};
struct Definition { Setting id; const char *key; const char *title; bool defaultValue; };
constexpr std::array<Definition,5> kDefinitions{{
    {Setting::haptics, "haptics", "Phản hồi rung", true},
    {Setting::reducedMotion, "reducedMotion", "Giảm chuyển động", false},
    {Setting::compactLayout, "compactLayout", "Bố cục gọn", false},
    {Setting::softBackground, "softBackground", "Nền dịu mắt", true},
    {Setting::rememberSettings, "rememberSettings", "Ghi nhớ cài đặt", true},
}};
constexpr const Definition *find(std::string_view key) noexcept {
    for(const auto &definition:kDefinitions) if(key==definition.key) return &definition;
    return nullptr;
}
constexpr bool inRange(std::uint32_t milliseconds) noexcept {
    return milliseconds >= 120u && milliseconds <= 1500u;
}
constexpr std::uint32_t clampedAnimation(std::uint32_t milliseconds) noexcept {
    return milliseconds < 120u ? 120u : (milliseconds > 1500u ? 1500u : milliseconds);
}
}