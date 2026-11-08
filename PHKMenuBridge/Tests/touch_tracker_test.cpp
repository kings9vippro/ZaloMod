#include "../Core/PHKTouchTracker.hpp"
#include <cassert>
#include <cstdio>
using phk::FourFingerTap;using phk::TouchPhase;
static bool stroke(FourFingerTap& t,unsigned n,double delay=0,double extra=0,bool cancel=false){
    for(unsigned i=0;i<n;i++)assert(!t.feed(i+1,TouchPhase::began,delay+i*.02,float(10*i),25));
    bool found=false;
    for(unsigned i=0;i<n;i++){
        auto p=cancel&&i==0?TouchPhase::cancelled:TouchPhase::ended;
        found|=t.feed(i+1,p,delay+.20+extra+i*.02,float(10*i),25);
    }
    return found;
}
int main(){
    FourFingerTap t;
    assert(stroke(t,4));assert(stroke(t,4));
    assert(!stroke(t,3));assert(!stroke(t,5));
    assert(!stroke(t,4,0,2));assert(!stroke(t,4,0,0,true));
    for(unsigned i=0;i<4;i++)t.feed(i+1,TouchPhase::began,10+i*.01,i*10,20);
    assert(!t.feed(1,TouchPhase::moved,10.1,100,20));
    bool moved=false;
    for(unsigned i=0;i<4;i++)moved|=t.feed(i+1,TouchPhase::ended,10.2+i*.01,i==0?100:i*10,20);
    assert(!moved);assert(stroke(t,4));
    puts("PASS: four-finger state machine");
}