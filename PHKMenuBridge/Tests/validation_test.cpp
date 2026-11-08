#include "../Core/PHKValidation.hpp"
#include <cassert>
int main() {
  static_assert(sizeof(long long)==sizeof(std::int64_t));
  std::int64_t result=0;
  assert(phk::validTTL("30",0,&result)&&result==30000);
  assert(phk::validTTL("2",1,&result)&&result==7200000);
  assert(phk::validTTL("7",2,&result)&&result==604800000);
  assert(!phk::validTTL("0",0,&result));
  assert(!phk::validTTL("99999999",2,&result));
  assert(!phk::validTTL("12a",1,&result));
  assert(!phk::validTTL("-1",0,&result));
  assert(!phk::validTTL("1",9,&result));
  assert(!phk::validTTL("3",0,nullptr));
  assert(phk::validPrefix("!"));
  assert(!phk::validPrefix("abc"));
  return 0;
}
