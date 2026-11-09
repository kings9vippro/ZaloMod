#pragma once
#include <array>
#include <cstddef>
#include <cstdint>

namespace phk {
enum class TouchPhase : unsigned char { began, moved, ended, cancelled };
struct TouchPoint { double timestamp; float x; float y; };
class ThreeFingerTap final {
public:
    bool feed(std::uintptr_t identifier, TouchPhase phase, double timestamp, float x, float y) noexcept;
    void reset() noexcept;
    std::size_t activeTouches() const noexcept;
private:
    struct Slot { std::uintptr_t id=0; TouchPoint began{}; };
    std::array<Slot,3> slots_{};
    double first_=-1.0;
    unsigned peak_=0;
    bool invalid_=false;
};
}