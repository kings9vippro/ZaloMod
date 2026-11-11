#include "../Core/PHKCore.hpp"
#include <cassert>
#include <cmath>
#include <cstdio>
#include <limits>
using namespace phk;
int main(){
    assert(parseCommand(" .sticker ",true)==Command::sticker);
    assert(parseCommand(".sticker",false)==Command::missingImage);
    assert(parseCommand(".color random",false)==Command::colorRandom);
    assert(parseCommand(".help",false)==Command::help);
    assert(parseCommand(" .menu ",false)==Command::menu);
    assert(parseCommand(".color 7",false)==Command::colorIndex);
    assert(parseCommand(".color 8",false)==Command::none);
    assert(parseCommand(".font 18",false)==Command::fontSize);
    assert(parseCommand(".font 30",false)==Command::none);
    assert(parseCommand(".delay 1",false)==Command::setDelay);
    assert(parseCommand(".delay 60",false)==Command::setDelay);
    assert(parseCommand(".delay 0",false)==Command::none);
    assert(parseCommand(".tagall hidden 100",false)==Command::none);
    assert(parseCommandDetailed(".color 3",false).value==3);
    assert(parseCommandDetailed(".font 14",false).value==14);
    assert(parseCommandDetailed(".delay 5",false).value==5);
    assert(parseCommand(".sticker extra",true)==Command::none);
    assert(indexAt(0,400)==0 && indexAt(399.9,400)==4);
    assert(indexAt(200,400)==2 && indexAt(-20,400)==0);
    assert(indexAt(std::numeric_limits<double>::quiet_NaN(),400)==-1);
    assert(indexAt(99,0)==-1);
    assert(swipeIndex(0,-80)==1 && swipeIndex(4,-80)==4);
    assert(swipeIndex(2,80)==1 && swipeIndex(2,20)==2);
    assert(swipeIndex(2,std::numeric_limits<double>::infinity())==2);
    assert(!validDelay(0,0)&&validDelay(1000,0));
    assert(validDelay(60000,9)&&!validDelay(60001,9));
    assert(!validDelay(1000,10));
    for(std::uint64_t i=0;i<1000;i++){
        const auto a=paletteAt(i),b=paletteAt(i+7);
        assert(a.r==b.r && a.g==b.g && a.b==b.b);
    }
    std::puts("PASS: 5-tab docking, gesture bounds, command parser, curated 7-color palette, opt-in delayed-send limits");
}