#include "PHKValidation.hpp"
#include <cctype>
#include <limits>
namespace phk {
bool validTTL(const std::string &digits,int unit,std::int64_t *milliseconds) noexcept {
    if (!milliseconds || digits.empty() || digits.size()>8 || unit<0 || unit>2) return false;
    std::int64_t number=0;
    for(unsigned char c:digits) {
      if (c<'0'||c>'9') return false;
      number=number*10+(c-'0');
    }
    // Bound to 30 days to protect legacy code paths from overflows and mistakes.
    if(number<=0) return false;
    const std::int64_t scale[] = {1000,3600000,86400000};
    if (number > (30LL*86400000)/scale[unit]) return false;
    *milliseconds=number*scale[unit];return true;
}
bool validPrefix(const std::string &p) noexcept {
    if(p.size()!=1)return false;
    auto c=static_cast<unsigned char>(p[0]);
    return c=='!'||c=='/'||c=='.'||c=='#';
}
}
