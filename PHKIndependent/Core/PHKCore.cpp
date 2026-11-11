#include "PHKCore.hpp"
#include <algorithm>
#include <cmath>

namespace phk {
namespace {
std::string_view trim(std::string_view s) noexcept {
    while(!s.empty() && (s.front()==' '||s.front()=='\t'||s.front()=='\n'))s.remove_prefix(1);
    while(!s.empty() && (s.back()==' '||s.back()=='\t'||s.back()=='\n'))s.remove_suffix(1);
    return s;
}
}
Command parseCommand(std::string_view input,bool image) noexcept {
    input=trim(input);
    if(input==".sticker" || input=="/sticker")return image?Command::sticker:Command::missingImage;
    if(input==".color random" || input==".mau random")return Command::colorRandom;
    if(input==".help" || input=="/help")return Command::help;
    return Command::none;
}
int indexAt(double x,double width,int count) noexcept {
    if(count<=0 || count>20 || !std::isfinite(x) || !std::isfinite(width) || width<=0)return -1;
    if(x<=0)return 0;
    if(x>=width)return count-1;
    return std::clamp(static_cast<int>(x*count/width),0,count-1);
}
int swipeIndex(int current,double dx,int count) noexcept {
    if(count<=0 || count>20)return -1;
    current=std::clamp(current,0,count-1);
    if(!std::isfinite(dx) || std::abs(dx)<32.0)return current;
    return std::clamp(current+(dx<0?1:-1),0,count-1);
}
RGB paletteAt(std::uint64_t index) noexcept {return kPalette[index%kPalette.size()];}
bool validDelay(std::uint32_t ms,std::size_t pending) noexcept {
    return ms>=kMinimumDelayMs && ms<=kMaximumDelayMs && pending<kMaximumPending;
}
}