const c = @import("c.zig");

pub fn context() c.sg_context_desc {
    return c.sg_context_desc {
        .color_format = @intCast(u32, c.sapp_color_format()),
        .depth_format = @intCast(u32, c.sapp_depth_format()),
        .sample_count = c.sapp_sample_count(),
        .gl = .{
            .force_gles2 = c.sapp_gles2(),
        },
        .metal = .{
            .device = c.sapp_metal_get_device(),
            .renderpass_descriptor_cb = c.sapp_metal_get_renderpass_descriptor,
            .renderpass_descriptor_userdata_cb = null,
            .drawable_cb = c.sapp_metal_get_drawable,
            .drawable_userdata_cb = null,
            .user_data = null,
        },
        .d3d11 = .{
            .device = c.sapp_d3d11_get_device(),
            .device_context = c.sapp_d3d11_get_device_context(),
            .render_target_view_cb = c.sapp_d3d11_get_render_target_view,
            .render_target_view_userdata_cb = null,
            .depth_stencil_view_cb = c.sapp_d3d11_get_depth_stencil_view,
            .depth_stencil_view_userdata_cb = null,
            .user_data = null,
        },
        .wgpu = .{
            .device = c.sapp_wgpu_get_device(),
            .render_view_cb = c.sapp_wgpu_get_render_view,
            .render_view_userdata_cb = null,
            .resolve_view_cb = c.sapp_wgpu_get_resolve_view,
            .resolve_view_userdata_cb = null,
            .depth_stencil_view_cb = c.sapp_wgpu_get_depth_stencil_view,
            .depth_stencil_view_userdata_cb = null,
            .user_data = null,
        }
    };
}
