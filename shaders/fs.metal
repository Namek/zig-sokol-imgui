#include <metal_stdlib>
using namespace metal;
struct ps_in {
  float4 color;
};
fragment float4 _main(ps_in in [[stage_in]]) {
  return in.color;
}
