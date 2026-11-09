#include "PHKTouchTracker.hpp"
#include <algorithm>
#include <cmath>

namespace phk {
void ThreeFingerTap::reset() noexcept {
    for(auto &slot:slots_)slot={};
    first_=-1.0;peak_=0;invalid_=false;
}
std::size_t ThreeFingerTap::activeTouches() const noexcept {
    std::size_t count=0;
    for(const auto &slot:slots_)if(slot.id!=0)++count;
    return count;
}
bool ThreeFingerTap::feed(std::uintptr_t identifier,TouchPhase phase,double timestamp,float x,float y) noexcept {
    if(identifier==0 || !std::isfinite(timestamp) || !std::isfinite(x) || !std::isfinite(y)){
        reset();return false;
    }
    if(phase==TouchPhase::began){
        if(activeTouches()==0)reset();
        for(const auto &slot:slots_)if(slot.id==identifier)return false;
        if(first_<0)first_=timestamp;
        if(timestamp<first_ || timestamp-first_>.30)invalid_=true;
        if(activeTouches()==slots_.size()){invalid_=true;return false;}
        for(auto &slot:slots_)if(slot.id==0){slot.id=identifier;slot.began={timestamp,x,y};break;}
        peak_=std::max(peak_,static_cast<unsigned>(activeTouches()));
        return false;
    }
    Slot *current=nullptr;
    for(auto &slot:slots_)if(slot.id==identifier){current=&slot;break;}
    if(!current)return false;
    const float dx=x-current->began.x,dy=y-current->began.y;
    if(dx*dx+dy*dy>625.0f)invalid_=true;
    if(phase==TouchPhase::cancelled)invalid_=true;
    if(phase==TouchPhase::ended || phase==TouchPhase::cancelled){
        current->id=0;
        if(activeTouches()==0){
            const bool accepted=!invalid_ && peak_==3 && timestamp>=first_ && timestamp-first_<=.75;
            reset();return accepted;
        }
    }
    return false;
}
}