#include "Preferences.hpp"
namespace phk {
static_assert(kDefinitions.size() == static_cast<std::size_t>(Setting::count));
static_assert(find("haptics") != nullptr);
static_assert(find("unknown") == nullptr);
static_assert(clampedAnimation(50) == 120);
static_assert(clampedAnimation(2000) == 1500);
}