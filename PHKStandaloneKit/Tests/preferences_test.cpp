#include "../Core/Preferences.hpp"
#include <cassert>
#include <cstdio>
int main() {
    using namespace phk;
    assert(kDefinitions.size()==5);
    for (const auto &d:kDefinitions) {
        assert(find(d.key)==&d);
        assert(d.title && d.title[0]);
    }
    assert(find("cookie")==nullptr);
    assert(inRange(250) && !inRange(50) && !inRange(10000));
    assert(clampedAnimation(0)==120);
    assert(clampedAnimation(1000)==1000);
    assert(clampedAnimation(100000)==1500);
    puts("PASS: settings schema, no unknown keys, bounded animation values");
}