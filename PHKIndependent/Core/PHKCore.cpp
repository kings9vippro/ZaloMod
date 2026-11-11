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
static int decimal(std::string_view text) noexcept {
    if(text.empty() || text.size()>3)return -1;
    int result=0;
    for(const char c:text){
        if(c<'0'||c>'9')return -1;
        result=result*10+(c-'0');
    }
    return result;
}
ParsedCommand parseCommandDetailed(std::string_view input,bool hasImage) noexcept {
    input=trim(input);
    if(input==".menu" || input=="/menu")return {Command::menu,0};
    if(input==".sticker" || input=="/sticker")
        return {hasImage?Command::sticker:Command::missingImage,0};
    if(input==".color random" || input==".mau random")return {Command::colorRandom,0};
    if(input==".help" || input=="/help")return {Command::help,0};
    if(input.size()>7 && input.substr(0,7)==".color "){
        const int v=decimal(input.substr(7));
        if(v>=1&&v<=7)return {Command::colorIndex,v};
    }
    if(input.size()>6 && input.substr(0,6)==".font "){
        const int v=decimal(input.substr(6));
        if(v>=10&&v<=18)return {Command::fontSize,v};
    }
    if(input.size()>7 && input.substr(0,7)==".delay "){
        const int v=decimal(input.substr(7));
        if(v>=1&&v<=60)return {Command::setDelay,v};
    }
    return {Command::none,0};
}
Command parseCommand(std::string_view input,bool image) noexcept {
    return parseCommandDetailed(input,image).kind;
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