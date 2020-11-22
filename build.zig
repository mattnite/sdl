const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const Allocator = std.mem.Allocator;

const sdl2 = @import("deps.zig").pkgs.sdl2_c;
const Sdl2Builder = @import("src/builder.zig");

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const sdl2_builder = Sdl2Builder.init(b.allocator, sdl2.path);

    const opts = Sdl2Builder.Options.create(target, .{});
    const lib = try sdl2_builder.addLibrary(b, .shared, .{}, opts, mode, target);
    lib.install();
}

//pub fn build(b: *Builder) !void {
//    b.setPreferredReleaseMode(.ReleaseFast);
//    const target = b.standardTargetOptions(.{});
//    const mode = b.standardReleaseOptions();
//    const tag = target.os_tag orelse std.builtin.os.tag;
//
//    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//    const allocator = &arena.allocator;
//    defer arena.deinit();
//
//    var subsystems: SubsystemConfig = undefined;
//    inline for (std.meta.fields(@TypeOf(subsystems))) |field| {
//        @field(subsystems, field.name) = b.option(
//            bool,
//            field.name,
//            "Enable/Disable " ++ field.name ++ " subsystem (enabled)",
//        ) orelse true;
//    }
//
//    const shared = b.option(bool, "shared", "Compile as shared library") orelse false;
//    const lib = if (shared)
//        b.addSharedLibrary("SDL", null, .{ .major = 2, .minor = 0, .patch = 13 })
//    else
//        b.addStaticLibrary("SDL", null);
//
//    lib.addIncludeDir("c/include");
//
//    const disk_audio = b.option(bool, "disk_audio", "Support the disk writer audio driver") orelse true;
//    const dummy_audio = b.option(bool, "dummy_audio", "Support the dummy audio driver") orelse true;
//    const video_directfb = b.option(bool, "video_directfb", "Use DirectFB video driver") orelse false;
//    const video_opengl = b.option(bool, "video_opengl", "Include OpenGL support") orelse true;
//    const video_opengles = b.option(bool, "video_opengles", "Include OpenGL ES support") orelse true;
//    const video_dummy = b.option(bool, "video_dummy", "Use dummy video driver") orelse true;
//    //const dlopen = b.option(bool, "dlopen", "Use dlopen for shared object loading") orelse
//    //    if (tag == .emscripten) false else true;
//    const joystick_virtual = b.option(bool, "joystick_virtual", "Enable the virtual-joystick driver") orelse true;
//    const video_offscreen = b.option(bool, "video_offscreen", "Use offscreen video driver") orelse false;
//
//    if (std.builtin.endian == .Big) {
//        lib.defineCMacro("SDL_BYTEORDER=SDL_BIG_ENDIAN");
//    } else {
//        lib.defineCMacro("SDL_BYTEORDER=SDL_LIL_ENDIAN");
//    }
//
//    if (subsystems.joystick) {
//        add_c_srcs(lib, joystick_srcs, null);
//        if (joystick_virtual) add_c_srcs(lib, joystick_virtual_srcs, null);
//    } else if (subsystems.haptic) {
//        return error.JoystickRequired;
//    }
//
//    if (subsystems.audio) {
//        if (dummy_audio) add_c_srcs(lib, dummy_audio_srcs, null);
//        if (disk_audio) add_c_srcs(lib, disk_audio_srcs, null);
//    }
//
//    if (subsystems.video) {
//        if (video_dummy) add_c_srcs(lib, video_dummy_srcs, null);
//        if (video_offscreen) add_c_srcs(lib, video_offscreen_srcs, null);
//    }
//
//    // TODO: allow targeting/cross compiling ?
//    switch (tag) {
//        .emscripten => {
//            if (subsystems.audio) add_c_srcs(lib, emscripten_audio_srcs, null);
//            if (subsystems.filesystem) add_c_srcs(lib, emscripten_filesystem_srcs, null);
//            if (subsystems.joystick) add_c_srcs(lib, emscripten_joystick_srcs, null);
//            if (subsystems.power) add_c_srcs(lib, emscripten_power_srcs, null);
//            if (subsystems.locale) add_c_srcs(lib, emscripten_locale_srcs, null);
//            if (subsystems.timers) add_c_srcs(lib, unix_timers_srcs, null);
//            if (subsystems.video) add_c_srcs(lib, emscripten_video_srcs, null);
//        },
//        .linux, .freebsd, .netbsd, .openbsd, .dragonfly, .aix, .solaris, .minix => {
//            // audio
//            if (subsystems.audio) {
//                switch (tag) {
//                    .solaris => add_c_srcs(lib, solaris_audio_srcs, null),
//                    .netbsd => add_c_srcs(lib, netbsd_audio_srcs, null),
//                    .aix => add_c_srcs(lib, aix_audio_srcs, null),
//                    else => {},
//                }
//                // TODO audio checks
//            }
//
//            if (subsystems.video) {
//                // TODO video checks
//            }
//
//            if (tag == .linux) {
//                // TODO: check for input events somehow
//                // const has_input_events = @hasDecl(c, "EVIOCGNAME");
//                // if (has_input_events) {
//                //     add_c_srcs(linux_haptic_srcs, null);
//                // }
//                if (subsystems.joystick) {
//                    add_c_srcs(lib, linux_joystick_srcs, null);
//                    add_c_srcs(lib, steam_joystick_srcs, null);
//                }
//            }
//
//            add_c_srcs(lib, unix_core_srcs, null);
//        },
//        .windows => {
//            add_c_srcs(lib, windows_core_srcs, null);
//        },
//        .ios, .macosx, .watchos, .tvos => add_c_srcs(lib, apple_srcs, null),
//        else => unreachable,
//    }
//
//    add_c_srcs(lib, general_srcs, null);
//
//    lib.linkLibC();
//    lib.setBuildMode(mode);
//    lib.setTarget(target);
//    lib.install();
//}

const generic_srcs = &[_][]const u8{};

const joystick_srcs = &[_][]const u8{
    "src/joystick/SDL_gamecontroller.c",
    "src/joystick/SDL_joystick.c",
};

const dummy_audio_srcs = &[_][]const u8{
    "src/audio/dummy/SDL_dummyaudio.c",
};

const disk_audio_srcs = &[_][]const u8{
    "src/audio/disk/SDL_diskaudio.c",
};

const joystick_virtual_srcs = &[_][]const u8{
    "src/joystick/virtual/SDL_virtualjoystick.c",
};

const video_dummy_srcs = &[_][]const u8{
    "src/video/dummy/SDL_nullevents.c",
    "src/video/dummy/SDL_nullframebuffer.c",
    "src/video/dummy/SDL_nullvideo.c",
};

const video_offscreen_srcs = &[_][]const u8{
    "src/video/offscreen/SDL_offscreenevents.c",
    "src/video/offscreen/SDL_offscreenframebuffer.c",
    "src/video/offscreen/SDL_offscreenopengl.c",
    "src/video/offscreen/SDL_offscreenvideo.c",
    "src/video/offscreen/SDL_offscreenwindow.c",
};

const loadso_srcs = &[_][]const u8{
    "src/loadso/dlopen/SDL_sysloadso.c",
};

const unix_timers_srcs = &[_][]const u8{
    "src/timer/unix/SDL_systimer.c",
};

const unix_core_srcs = &[_][]const u8{
    "src/core/unix/SDL_poll.c",
};

const emscripten_audio_srcs = &[_][]const u8{
    "src/audio/emscripten/SDL_emscriptenaudio.c",
};

const emscripten_filesystem_srcs = &[_][]const u8{
    "src/filesystem/emscripten/SDL_sysfilesystem.c",
};

const emscripten_joystick_srcs = &[_][]const u8{
    "src/joystick/emscripten/SDL_sysjoystick.c",
};

const emscripten_power_srcs = &[_][]const u8{
    "src/power/emscripten/SDL_syspower.c",
};

const emscripten_locale_srcs = &[_][]const u8{
    "src/locale/emscripten/SDL_syslocale.c",
};

const emscripten_video_srcs = &[_][]const u8{
    "src/video/emscripten/SDL_emscriptenevents.c",
    "src/video/emscripten/SDL_emscriptenframebuffer.c",
    "src/video/emscripten/SDL_emscriptenmouse.c",
    "src/video/emscripten/SDL_emscriptenopengles.c",
    "src/video/emscripten/SDL_emscriptenvideo.c",
};

const solaris_audio_srcs = &[_][]const u8{};
const netbsd_audio_srcs = &[_][]const u8{};
const aix_audio_srcs = &[_][]const u8{};
const linux_joystick_srcs = &[_][]const u8{};
const steam_joystick_srcs = &[_][]const u8{};

const windows_core_srcs = &[_][]const u8{};
const apple_srcs = &[_][]const u8{};
const unix_srcs = &[_][]const u8{};

const general_srcs = &[_][]const u8{
    "src/SDL_assert.c",
    "src/SDL.c",
    "src/SDL_dataqueue.c",
    "src/SDL_error.c",
    "src/SDL_hints.c",
    "src/SDL_log.c",
    "src/atomic/SDL_atomic.c",
    "src/atomic/SDL_spinlock.c",
    "src/audio/SDL_audio.c",
    "src/audio/SDL_audiocvt.c",
    "src/audio/SDL_audiodev.c",
    "src/audio/SDL_audiotypecvt.c",
    "src/audio/SDL_mixer.c",
    "src/audio/SDL_wave.c",
    "src/cpuinfo/SDL_cpuinfo.c",
    "src/dynapi/SDL_dynapi.c",
    "src/events/SDL_clipboardevents.c",
    "src/events/SDL_displayevents.c",
    "src/events/SDL_dropevents.c",
    "src/events/SDL_events.c",
    "src/events/SDL_gesture.c",
    "src/events/SDL_keyboard.c",
    "src/events/SDL_mouse.c",
    "src/events/SDL_quit.c",
    "src/events/SDL_touch.c",
    "src/events/SDL_windowevents.c",
    "src/file/SDL_rwops.c",
    "src/haptic/SDL_haptic.c",
    "src/libm/e_atan2.c",
    "src/libm/e_exp.c",
    "src/libm/e_fmod.c",
    "src/libm/e_log10.c",
    "src/libm/e_log.c",
    "src/libm/e_pow.c",
    "src/libm/e_rem_pio2.c",
    "src/libm/e_sqrt.c",
    "src/libm/k_cos.c",
    "src/libm/k_rem_pio2.c",
    "src/libm/k_sin.c",
    "src/libm/k_tan.c",
    "src/libm/s_atan.c",
    "src/libm/s_copysign.c",
    "src/libm/s_cos.c",
    "src/libm/s_fabs.c",
    "src/libm/s_floor.c",
    "src/libm/s_scalbn.c",
    "src/libm/s_sin.c",
    "src/libm/s_tan.c",
    "src/locale/SDL_locale.c",
    "src/power/SDL_power.c",
    "src/render/SDL_d3dmath.c",
    "src/render/SDL_render.c",
    "src/render/SDL_yuv_sw.c",
    "src/render/direct3d11/SDL_render_d3d11.c",
    "src/render/direct3d11/SDL_shaders_d3d11.c",
    "src/render/direct3d/SDL_render_d3d.c",
    "src/render/direct3d/SDL_shaders_d3d.c",
    "src/render/opengles2/SDL_render_gles2.c",
    "src/render/opengles2/SDL_shaders_gles2.c",
    "src/render/opengles/SDL_render_gles.c",
    "src/render/opengl/SDL_render_gl.c",
    "src/render/opengl/SDL_shaders_gl.c",
    "src/render/psp/SDL_render_psp.c",
    "src/render/software/SDL_blendfillrect.c",
    "src/render/software/SDL_blendline.c",
    "src/render/software/SDL_blendpoint.c",
    "src/render/software/SDL_drawline.c",
    "src/render/software/SDL_drawpoint.c",
    "src/render/software/SDL_render_sw.c",
    "src/render/software/SDL_rotate.c",
    "src/sensor/SDL_sensor.c",
    "src/stdlib/SDL_getenv.c",
    "src/stdlib/SDL_iconv.c",
    "src/stdlib/SDL_malloc.c",
    "src/stdlib/SDL_qsort.c",
    "src/stdlib/SDL_stdlib.c",
    "src/stdlib/SDL_string.c",
    "src/stdlib/SDL_strtokr.c",
    "src/thread/SDL_thread.c",
    "src/timer/SDL_timer.c",
    "src/video/SDL_blit_0.c",
    "src/video/SDL_blit_1.c",
    "src/video/SDL_blit_A.c",
    "src/video/SDL_blit_auto.c",
    "src/video/SDL_blit.c",
    "src/video/SDL_blit_copy.c",
    "src/video/SDL_blit_N.c",
    "src/video/SDL_blit_slow.c",
    "src/video/SDL_bmp.c",
    "src/video/SDL_clipboard.c",
    "src/video/SDL_egl.c",
    "src/video/SDL_fillrect.c",
    "src/video/SDL_pixels.c",
    "src/video/SDL_rect.c",
    "src/video/SDL_RLEaccel.c",
    "src/video/SDL_shape.c",
    "src/video/SDL_stretch.c",
    "src/video/SDL_surface.c",
    "src/video/SDL_video.c",
    "src/video/SDL_vulkan_utils.c",
    "src/video/SDL_yuv.c",
    "src/video/yuv2rgb/yuv_rgb.c",
};
