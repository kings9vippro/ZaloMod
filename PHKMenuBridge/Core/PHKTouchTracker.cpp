#include "PHKTouchTracker.hpp"
#include <algorithm>
#include <cmath>
namespace phk {
void ThreeFingerTap::reset() noexcept {
    active_.clear(); first_ = -1.0; maxActive_ = 0; invalid_ = false;
}
bool ThreeFingerTap::feed(std::uintptr_t identifier, TouchPhase phase, double timestamp, float x, float y) noexcept {
    if(identifier==0 || !std::isfinite(timestamp) || !std::isfinite(x) || !std::isfinite(y)) {
        invalid_=true;return false;
    }
    if(phase==TouchPhase::began){
        if(active_.empty()){first_=timestamp;maxActive_=0;invalid_=false;}
        auto inserted=active_.emplace(identifier,TouchPoint{timestamp,x,y});
        if(!inserted.second){invalid_=true;return false;}
        maxActive_=std::max(maxActive_,static_cast<unsigned>(active_.size()));
        if(maxActive_>3 || (first_>=0 && timestamp-first_>.35))invalid_=true;
        return false;
    }
    auto it=active_.find(identifier);
    if(it==active_.end())return false;
    float dx=x-it->second.x,dy=y-it->second.y;
    if(dx*dx+dy*dy>900.0f)invalid_=true;
    if(phase==TouchPhase::cancelled)invalid_=true;
    if(phase==TouchPhase::ended || phase==TouchPhase::cancelled){
        active_.erase(it);
        if(active_.empty()){
            bool detected=!invalid_ && maxActive_==3 && timestamp>=first_ && timestamp-first_<=.80;
            reset();return detected;
        }
    }
    return false;
}
}