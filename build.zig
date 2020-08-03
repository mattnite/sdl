const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const Allocator = std.mem.Allocator;

pub fn build(b: *Builder) !void {
    const name = "SDL";

    const shared = b.option(bool, "shared", "Compile as shared library") orelse false;
    const lib = if (shared)
        b.addSharedLibrary(name, null, .{ .major = 2, .minor = 0, .patch = 13 })
    else
        b.addStaticLibrary(name, null);

    b.setPreferredReleaseMode(.ReleaseFast);
    const mode = b.standardReleaseOptions();

    lib.addIncludeDir("c/include");
    for (c_source) |file| {
        lib.addCSourceFile(file, &[_][]const u8{});
    }

    if (std.builtin.endian == .Big) {
        lib.defineCMacro("SDL_BYTEORDER=SDL_BIG_ENDIAN");
    } else {
        lib.defineCMacro("SDL_BYTEORDER=SDL_LIL_ENDIAN");
    }

    lib.linkLibC();
    lib.setBuildMode(mode);
    lib.install();
}

const c_source = &[_][]const u8{
    "c/src/SDL_dataqueue.c",
    "c/src/SDL_error.c",
    "c/src/SDL_hints.c",
    "c/src/SDL_assert.c",
    "c/src/SDL.c",
    "c/src/SDL_log.c",
    "c/src/audio/SDL_audiodev.c",
    "c/src/audio/SDL_audiotypecvt.c",
    "c/src/audio/SDL_audio.c",
    "c/src/audio/SDL_wave.c",
    "c/src/audio/SDL_mixer.c",
    "c/src/audio/SDL_audiocvt.c",
    "c/src/audio/dummy/SDL_dummyaudio.c",
    "c/src/cpuinfo/SDL_cpuinfo.c",
    "c/src/events/SDL_touch.c",
    "c/src/events/SDL_mouse.c",
    "c/src/events/SDL_keyboard.c",
    "c/src/events/SDL_events.c",
    "c/src/events/SDL_dropevents.c",
    "c/src/events/SDL_quit.c",
    "c/src/events/SDL_windowevents.c",
    "c/src/events/SDL_gesture.c",
    "c/src/events/SDL_displayevents.c",
    "c/src/events/SDL_clipboardevents.c",
    "c/src/file/SDL_rwops.c",
    "c/src/haptic/SDL_haptic.c",
    "c/src/haptic/dummy/SDL_syshaptic.c",
    "c/src/joystick/SDL_joystick.c",
    "c/src/joystick/SDL_gamecontroller.c",
    "c/src/joystick/dummy/SDL_sysjoystick.c",
    "c/src/loadso/dummy/SDL_sysloadso.c",
    "c/src/power/SDL_power.c",
    "c/src/filesystem/dummy/SDL_sysfilesystem.c",
    "c/src/render/SDL_render.c",
    "c/src/render/SDL_d3dmath.c",
    "c/src/render/SDL_yuv_sw.c",
    "c/src/render/software/SDL_blendpoint.c",
    "c/src/render/software/SDL_render_sw.c",
    "c/src/render/software/SDL_drawpoint.c",
    "c/src/render/software/SDL_drawline.c",
    "c/src/render/software/SDL_rotate.c",
    "c/src/render/software/SDL_blendline.c",
    "c/src/render/software/SDL_blendfillrect.c",
    "c/src/sensor/SDL_sensor.c",
    "c/src/sensor/dummy/SDL_dummysensor.c",
    "c/src/stdlib/SDL_string.c",
    "c/src/stdlib/SDL_malloc.c",
    "c/src/stdlib/SDL_getenv.c",
    "c/src/stdlib/SDL_strtokr.c",
    "c/src/stdlib/SDL_stdlib.c",
    "c/src/stdlib/SDL_iconv.c",
    "c/src/stdlib/SDL_qsort.c",
    "c/src/thread/SDL_thread.c",
    "c/src/thread/generic/SDL_syssem.c",
    "c/src/thread/generic/SDL_systhread.c",
    "c/src/thread/generic/SDL_systls.c",
    "c/src/thread/generic/SDL_sysmutex.c",
    "c/src/thread/generic/SDL_syscond.c",
    "c/src/timer/SDL_timer.c",
    "c/src/timer/dummy/SDL_systimer.c",
    "c/src/video/SDL_pixels.c",
    "c/src/video/SDL_stretch.c",
    "c/src/video/SDL_blit_slow.c",
    "c/src/video/SDL_RLEaccel.c",
    "c/src/video/SDL_blit_1.c",
    "c/src/video/SDL_blit_N.c",
    "c/src/video/SDL_video.c",
    "c/src/video/SDL_fillrect.c",
    "c/src/video/SDL_blit_copy.c",
    "c/src/video/SDL_clipboard.c",
    "c/src/video/SDL_yuv.c",
    "c/src/video/SDL_shape.c",
    "c/src/video/SDL_blit_A.c",
    "c/src/video/SDL_blit_0.c",
    "c/src/video/SDL_surface.c",
    "c/src/video/SDL_vulkan_utils.c",
    "c/src/video/SDL_rect.c",
    "c/src/video/SDL_blit.c",
    "c/src/video/SDL_blit_auto.c",
    "c/src/video/SDL_bmp.c",
    "c/src/video/SDL_egl.c",
    "c/src/video/dummy/SDL_nullevents.c",
    "c/src/video/dummy/SDL_nullvideo.c",
    "c/src/video/dummy/SDL_nullframebuffer.c",
};
