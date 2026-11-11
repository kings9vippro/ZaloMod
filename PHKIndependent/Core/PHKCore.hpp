#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace phk {
constexpr int kTabCount=5;
struct RGB { std::uint8_t r,g,b; };
inline constexpr std::array<RGB,7> kPalette{{
    {58,133,255},   // balanced blue
    {0,191,166},    // teal
    {139,92,246},   // violet
    {236,72,153},   // rose
    {245,158,11},   // amber
    {34,197,94},    // green
    {239,68,68},    // red
}};
enum class Command : std::uint8_t {
    none, sticker, colorRandom, help, missingImage
};
Command parseCommand(std::string_view input, bool hasRepliedImage) noexcept;
int indexAt(double x,double width,int count=kTabCount) noexcept;
int swipeIndex(int current,double dx,int count=kTabCount) noexcept;
RGB paletteAt(std::uint64_t index) noexcept;
bool validDelay(std::uint32_t ms,std::size_t pending) noexcept;
constexpr std::uint32_t kMinimumDelayMs=1000;
constexpr std::uint32_t kMaximumDelayMs=60000;
constexpr std::size_t kMaximumPending=10;
}