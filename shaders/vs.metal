#include <metal_stdlib>
using namespace metal;
struct vs_in {
  float3 pos [[attribute(0)]];
  float4 color [[attribute(1)]];
};
struct vs_out {
  float4 color;
  float4 pos [[position]];
};
vertex vs_out _main(vs_in in[[stage_in]]) {
  vs_out out;
  out.pos = float4(in.pos.xy * float2(1.0, 1.0), 0.0, 1.0);
  out.color = in.color;
  return out;
}
