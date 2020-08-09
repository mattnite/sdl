const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const Allocator = std.mem.Allocator;

const SubsystemConfig = struct {
    atomic: bool,
    audio: bool,
    video: bool,
    render: bool,
    events: bool,
    joystick: bool,
    haptic: bool,
    power: bool,
    threads: bool,
    timers: bool,
    file: bool,
    loadso: bool,
    cpuinfo: bool,
    filesystem: bool,
    //dlopen: bool,
    sensor: bool,
    locale: bool,
};

fn add_c_srcs(lib: *LibExeObjStep, srcs: []const []const u8, args: ?[]const []const u8) void {
    for (srcs) |file| {
        if (args) |a| {
            lib.addCSourceFile(file, a);
        }
    }
}

pub fn build(b: *Builder) !void {
    b.setPreferredReleaseMode(.ReleaseFast);
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const tag = target.os_tag orelse std.builtin.os.tag;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = &arena.allocator;
    defer arena.deinit();

    var subsystems: SubsystemConfig = undefined;
    inline for (std.meta.fields(@TypeOf(subsystems))) |field| {
        @field(subsystems, field.name) = b.option(
            bool,
            field.name,
            "Enable/Disable " ++ field.name ++ " subsystem (enabled)",
        ) orelse true;
    }

    const shared = b.option(bool, "shared", "Compile as shared library") orelse false;
    const lib = if (shared)
        b.addSharedLibrary("SDL", null, .{ .major = 2, .minor = 0, .patch = 13 })
    else
        b.addStaticLibrary("SDL", null);

    lib.addIncludeDir("c/include");

    const disk_audio = b.option(bool, "disk_audio", "Support the disk writer audio driver") orelse true;
    const dummy_audio = b.option(bool, "dummy_audio", "Support the dummy audio driver") orelse true;
    const video_directfb = b.option(bool, "video_directfb", "Use DirectFB video driver") orelse false;
    const video_opengl = b.option(bool, "video_opengl", "Include OpenGL support") orelse true;
    const video_opengles = b.option(bool, "video_opengles", "Include OpenGL ES support") orelse true;
    const video_dummy = b.option(bool, "video_dummy", "Use dummy video driver") orelse true;
    //const dlopen = b.option(bool, "dlopen", "Use dlopen for shared object loading") orelse
    //    if (tag == .emscripten) false else true;
    const joystick_virtual = b.option(bool, "joystick_virtual", "Enable the virtual-joystick driver") orelse true;
    const video_offscreen = b.option(bool, "video_offscreen", "Use offscreen video driver") orelse false;

    if (std.builtin.endian == .Big) {
        lib.defineCMacro("SDL_BYTEORDER=SDL_BIG_ENDIAN");
    } else {
        lib.defineCMacro("SDL_BYTEORDER=SDL_LIL_ENDIAN");
    }

    if (subsystems.joystick) {
        add_c_srcs(lib, joystick_srcs, null);
        if (joystick_virtual) add_c_srcs(lib, joystick_virtual_srcs, null);
    } else if (subsystems.haptic) {
        return error.JoystickRequired;
    }

    if (subsystems.audio) {
        if (dummy_audio) add_c_srcs(lib, dummy_audio_srcs, null);
        if (disk_audio) add_c_srcs(lib, disk_audio_srcs, null);
    }

    if (subsystems.video) {
        if (video_dummy) add_c_srcs(lib, video_dummy_srcs, null);
        if (video_offscreen) add_c_srcs(lib, video_offscreen_srcs, null);
    }

    // TODO: allow targeting/cross compiling ?
    switch (tag) {
        .emscripten => {
            if (subsystems.audio) add_c_srcs(lib, emscripten_audio_srcs, null);
            if (subsystems.filesystem) add_c_srcs(lib, emscripten_filesystem_srcs, null);
            if (subsystems.joystick) add_c_srcs(lib, emscripten_joystick_srcs, null);
            if (subsystems.power) add_c_srcs(lib, emscripten_power_srcs, null);
            if (subsystems.locale) add_c_srcs(lib, emscripten_locale_srcs, null);
            if (subsystems.timers) add_c_srcs(lib, unix_timers_srcs, null);
            if (subsystems.video) add_c_srcs(lib, emscripten_video_srcs, null);
        },
        .linux, .freebsd, .netbsd, .openbsd, .dragonfly, .aix, .solaris, .minix => {
            // audio
            if (subsystems.audio) {
                switch (tag) {
                    .solaris => add_c_srcs(lib, solaris_audio_srcs, null),
                    .netbsd => add_c_srcs(lib, netbsd_audio_srcs, null),
                    .aix => add_c_srcs(lib, aix_audio_srcs, null),
                    else => {},
                }
                // TODO audio checks
            }

            if (subsystems.video) {
                // TODO video checks
            }

            if (tag == .linux) {
                // TODO: check for input events somehow
                // const has_input_events = @hasDecl(c, "EVIOCGNAME");
                // if (has_input_events) {
                //     add_c_srcs(linux_haptic_srcs, null);
                // }
                if (subsystems.joystick) {
                    add_c_srcs(lib, linux_joystick_srcs, null);
                    add_c_srcs(lib, steam_joystick_srcs, null);
                }
            }

            add_c_srcs(lib, unix_core_srcs, null);
        },
        .windows => {
            add_c_srcs(lib, windows_core_srcs, null);
        },
        .ios, .macosx, .watchos, .tvos => add_c_srcs(lib, apple_srcs, null),
        else => unreachable,
    }

    add_c_srcs(lib, general_srcs, null);

    lib.linkLibC();
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.install();
}

const generic_srcs = &[_][]const u8{};

const joystick_srcs = &[_][]const u8{
    "c/src/joystick/SDL_gamecontroller.c",
    "c/src/joystick/SDL_joystick.c",
};

const dummy_audio_srcs = &[_][]const u8{
    "c/src/audio/dummy/SDL_dummyaudio.c",
};

const disk_audio_srcs = &[_][]const u8{
    "c/src/audio/disk/SDL_diskaudio.c",
};

const joystick_virtual_srcs = &[_][]const u8{
    "c/src/joystick/virtual/SDL_virtualjoystick.c",
};

const video_dummy_srcs = &[_][]const u8{
    "c/src/video/dummy/SDL_nullevents.c",
    "c/src/video/dummy/SDL_nullframebuffer.c",
    "c/src/video/dummy/SDL_nullvideo.c",
};

const video_offscreen_srcs = &[_][]const u8{
    "c/src/video/offscreen/SDL_offscreenevents.c",
    "c/src/video/offscreen/SDL_offscreenframebuffer.c",
    "c/src/video/offscreen/SDL_offscreenopengl.c",
    "c/src/video/offscreen/SDL_offscreenvideo.c",
    "c/src/video/offscreen/SDL_offscreenwindow.c",
};

const loadso_srcs = &[_][]const u8{
    "c/src/loadso/dlopen/SDL_sysloadso.c",
};

const unix_timers_srcs = &[_][]const u8{
    "c/src/timer/unix/SDL_systimer.c",
};

const unix_core_srcs = &[_][]const u8{
    "c/src/core/unix/SDL_poll.c",
};

const emscripten_audio_srcs = &[_][]const u8{
    "c/src/audio/emscripten/SDL_emscriptenaudio.c",
};

const emscripten_filesystem_srcs = &[_][]const u8{
    "c/src/filesystem/emscripten/SDL_sysfilesystem.c",
};

const emscripten_joystick_srcs = &[_][]const u8{
    "c/src/joystick/emscripten/SDL_sysjoystick.c",
};

const emscripten_power_srcs = &[_][]const u8{
    "c/src/power/emscripten/SDL_syspower.c",
};

const emscripten_locale_srcs = &[_][]const u8{
    "c/src/locale/emscripten/SDL_syslocale.c",
};

const emscripten_video_srcs = &[_][]const u8{
    "c/src/video/emscripten/SDL_emscriptenevents.c",
    "c/src/video/emscripten/SDL_emscriptenframebuffer.c",
    "c/src/video/emscripten/SDL_emscriptenmouse.c",
    "c/src/video/emscripten/SDL_emscriptenopengles.c",
    "c/src/video/emscripten/SDL_emscriptenvideo.c",
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
    "c/src/SDL_assert.c",
    "c/src/SDL.c",
    "c/src/SDL_dataqueue.c",
    "c/src/SDL_error.c",
    "c/src/SDL_hints.c",
    "c/src/SDL_log.c",
    "c/src/atomic/SDL_atomic.c",
    "c/src/atomic/SDL_spinlock.c",
    "c/src/audio/SDL_audio.c",
    "c/src/audio/SDL_audiocvt.c",
    "c/src/audio/SDL_audiodev.c",
    "c/src/audio/SDL_audiotypecvt.c",
    "c/src/audio/SDL_mixer.c",
    "c/src/audio/SDL_wave.c",
    "c/src/cpuinfo/SDL_cpuinfo.c",
    "c/src/dynapi/SDL_dynapi.c",
    "c/src/events/SDL_clipboardevents.c",
    "c/src/events/SDL_displayevents.c",
    "c/src/events/SDL_dropevents.c",
    "c/src/events/SDL_events.c",
    "c/src/events/SDL_gesture.c",
    "c/src/events/SDL_keyboard.c",
    "c/src/events/SDL_mouse.c",
    "c/src/events/SDL_quit.c",
    "c/src/events/SDL_touch.c",
    "c/src/events/SDL_windowevents.c",
    "c/src/file/SDL_rwops.c",
    "c/src/haptic/SDL_haptic.c",
    "c/src/libm/e_atan2.c",
    "c/src/libm/e_exp.c",
    "c/src/libm/e_fmod.c",
    "c/src/libm/e_log10.c",
    "c/src/libm/e_log.c",
    "c/src/libm/e_pow.c",
    "c/src/libm/e_rem_pio2.c",
    "c/src/libm/e_sqrt.c",
    "c/src/libm/k_cos.c",
    "c/src/libm/k_rem_pio2.c",
    "c/src/libm/k_sin.c",
    "c/src/libm/k_tan.c",
    "c/src/libm/s_atan.c",
    "c/src/libm/s_copysign.c",
    "c/src/libm/s_cos.c",
    "c/src/libm/s_fabs.c",
    "c/src/libm/s_floor.c",
    "c/src/libm/s_scalbn.c",
    "c/src/libm/s_sin.c",
    "c/src/libm/s_tan.c",
    "c/src/locale/SDL_locale.c",
    "c/src/power/SDL_power.c",
    "c/src/render/SDL_d3dmath.c",
    "c/src/render/SDL_render.c",
    "c/src/render/SDL_yuv_sw.c",
    "c/src/render/direct3d11/SDL_render_d3d11.c",
    "c/src/render/direct3d11/SDL_shaders_d3d11.c",
    "c/src/render/direct3d/SDL_render_d3d.c",
    "c/src/render/direct3d/SDL_shaders_d3d.c",
    "c/src/render/opengles2/SDL_render_gles2.c",
    "c/src/render/opengles2/SDL_shaders_gles2.c",
    "c/src/render/opengles/SDL_render_gles.c",
    "c/src/render/opengl/SDL_render_gl.c",
    "c/src/render/opengl/SDL_shaders_gl.c",
    "c/src/render/psp/SDL_render_psp.c",
    "c/src/render/software/SDL_blendfillrect.c",
    "c/src/render/software/SDL_blendline.c",
    "c/src/render/software/SDL_blendpoint.c",
    "c/src/render/software/SDL_drawline.c",
    "c/src/render/software/SDL_drawpoint.c",
    "c/src/render/software/SDL_render_sw.c",
    "c/src/render/software/SDL_rotate.c",
    "c/src/sensor/SDL_sensor.c",
    "c/src/stdlib/SDL_getenv.c",
    "c/src/stdlib/SDL_iconv.c",
    "c/src/stdlib/SDL_malloc.c",
    "c/src/stdlib/SDL_qsort.c",
    "c/src/stdlib/SDL_stdlib.c",
    "c/src/stdlib/SDL_string.c",
    "c/src/stdlib/SDL_strtokr.c",
    "c/src/thread/SDL_thread.c",
    "c/src/timer/SDL_timer.c",
    "c/src/video/SDL_blit_0.c",
    "c/src/video/SDL_blit_1.c",
    "c/src/video/SDL_blit_A.c",
    "c/src/video/SDL_blit_auto.c",
    "c/src/video/SDL_blit.c",
    "c/src/video/SDL_blit_copy.c",
    "c/src/video/SDL_blit_N.c",
    "c/src/video/SDL_blit_slow.c",
    "c/src/video/SDL_bmp.c",
    "c/src/video/SDL_clipboard.c",
    "c/src/video/SDL_egl.c",
    "c/src/video/SDL_fillrect.c",
    "c/src/video/SDL_pixels.c",
    "c/src/video/SDL_rect.c",
    "c/src/video/SDL_RLEaccel.c",
    "c/src/video/SDL_shape.c",
    "c/src/video/SDL_stretch.c",
    "c/src/video/SDL_surface.c",
    "c/src/video/SDL_video.c",
    "c/src/video/SDL_vulkan_utils.c",
    "c/src/video/SDL_yuv.c",
    "c/src/video/yuv2rgb/yuv_rgb.c",
};
