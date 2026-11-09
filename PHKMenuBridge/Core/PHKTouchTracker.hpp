#pragma once
#include <cstdint>
#include <unordered_map>
namespace phk {
enum class TouchPhase : unsigned char { began, moved, ended, cancelled };
struct TouchPoint { double timestamp; float x; float y; };
class ThreeFingerTap final {
public:
    bool feed(std::uintptr_t identifier, TouchPhase phase, double timestamp, float x, float y) noexcept;
    void reset() noexcept;
    std::size_t activeTouches() const noexcept { return active_.size(); }
private:
    std::unordered_map<std::uintptr_t, TouchPoint> active_;
    double first_ = -1.0;
    unsigned maxActive_ = 0;
    bool invalid_ = false;
};
}