const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

allocator: *Allocator,
base_path: []const u8,

const Self = @This();
const name = "SDL2";

const version = std.build.Version{
    .major = 2,
    .minor = 0,
    .patch = 12,
};

pub const LibraryType = enum {
    shared,
    static,
};

pub fn init(allocator: *Allocator, base_path: []const u8) Self {
    return Self{
        .allocator = allocator,
        .base_path = base_path,
    };
}

pub fn path(self: Self, sub_path: []const u8) ![]const u8 {
    return std.fs.path.join(self.allocator, &[_][]const u8{ self.base_path, sub_path });
}

pub fn addMinimalLibrary(
    self: Self,
    b: *Builder,
    lib_type: LibraryType,
    mode: std.builtin.Mode,
    target: std.build.Target,
) !*LibExeObjStep {
    const lib = switch (lib_type) {
        .shared => b.addSharedLibrary(name, null, .{ .versioned = version }),
        .static => b.addStaticLibrary(name, null),
    };

    for (minimal_srcs) |src| {
        lib.addCSourceFile(
            try std.fs.path.join(self.allocator, &[_][]const u8{
                self.base_path,
                src,
            }),
            &[_][]const u8{},
        );
    }

    lib.addIncludeDir(try std.fs.path.join(self.allocator, &[_][]const u8{
        self.base_path,
        "include",
    }));
    lib.linkLibC();

    return lib;
}

pub fn addLibrary(
    self: Self,
    b: *Builder,
    lib_type: LibraryType,
    subsystems: Subsystems,
    opts: Options,
    mode: std.builtin.Mode,
    target: std.build.Target,
) !*LibExeObjStep {
    const lib = switch (lib_type) {
        .shared => b.addSharedLibrary(name, null, .{ .versioned = version }),
        .static => b.addStaticLibrary(name, null),
    };

    if (opts.backgrounding_signal) |sig| {
        lib.defineCMacro("SDL_BACKGROUNDING_SIGNAL={}", sig);
    }

    if (opts.foregrounding_signal) |sig| {
        lib.addCDefine("SDL_FOREGROUNDING_SIGNAL={}", sig);
    }

    if (subsystems.joystick) try self.addCSourceGlob("src/joystick/*.c");
    if (subsystems.haptic) {
        if (!subsystems.joystick) return error.HapticRequiresJoystick;
        try self.addCSourceGlob("src/haptic/*.c");
    }

    if (subsystems.sensor) try self.addCSourceGlob("src/sensor/*.c");
    if (subsystems.power) try self.addCSourceGlob("src/power/*.c");

    if (subsystems.audio) {
        if (opts.dummyaudio) try self.addCSourceGlob("src/audio/dummy/*.c");
        if (opts.diskaudio) try self.addCSourceGlob("src/audio/disk/*.c");
    }

    if (subsystems.video) {
        if (opts.video_dummy) try self.addCSourceGlob("src/video/dummy/*.c");
        if (opts.video_offscreen) try self.addCSourceGlob("src/video/offscreen/*.c");
    }

    // TODO: android
    // TODO: emscripten
    // TODO: Unix and not apple and not android and not riscos
    // TODO: Windows
    // TODO: apple
    lib.linkLibC();
    lib.setTarget(target);
    lib.setMode(mode);

    return lib;
}

pub const Subsystems = struct {
    atomic: bool = true,
    audio: bool = true,
    vidoe: bool = true,
    render: bool = true,
    events: bool = true,
    joystick: bool = true,
    haptic: bool = true,
    power: bool = true,
    threads: bool = true,
    timers: bool = true,
    file: bool = true,
    loadso: bool = true,
    cpuinfo: bool = true,
    filesystem: bool = true,
    dlopen: bool = true,
    sensor: bool = true,
};

pub const Options = struct {
    gcc_atomics: bool = true, // "Use gcc builtin atomics" ${OPT_DEF_GCC_ATOMICS})
    assembly: bool = true, // "Enable assembly routines" ${OPT_DEF_ASM})
    ssemath: bool, // "Allow GCC to use SSE floating point math" ${OPT_DEF_SSEMATH})
    mmx: bool = true, // "Use MMX assembly routines" ${OPT_DEF_ASM})
    @"3dnow": bool = true, // "Use 3Dnow! MMX assembly routines" ${OPT_DEF_ASM})
    sse: bool = true, // "Use SSE assembly routines" ${OPT_DEF_ASM})
    sse2: bool, // "Use SSE2 assembly routines" ${OPT_DEF_SSEMATH})
    sse3: bool, // "Use SSE3 assembly routines" ${OPT_DEF_SSEMATH})
    altivec: bool = true, // "Use Altivec assembly routines" ${OPT_DEF_ASM})
    armsimd: bool = true, // "use SIMD assembly blitters on ARM" ON)
    armneon: bool = true, // "use NEON assembly blitters on ARM" ON)
    diskaudio: bool = true, // "Support the disk writer audio driver" ON)
    dummyaudio: bool = true, // "Support the dummy audio driver" ON)
    video_directfb: bool = false, // "Use DirectFB video driver" OFF)
    directfb_shared: bool = false, // "Dynamically load directfb support" ON "VIDEO_DIRECTFB" OFF)
    video_dummy: bool = true, // "Use dummy video driver" ON)
    video_opengl: bool = true, // "Include OpenGL support" ON)
    video_opengles: bool = true, // "Include OpenGL ES support" ON)
    pthreads: bool = true, // "Use POSIX threads for multi-threading" ${SDL_PTHREADS_ENABLED_BY_DEFAULT})
    pthreads_sem: bool = true, // "Use pthread semaphores" ON "PTHREADS" OFF)
    sdl_dlopen: bool = true, // "Use dlopen for shared object loading" ${SDL_DLOPEN_ENABLED_BY_DEFAULT})
    oss: bool = true, // "Support the OSS audio API" ON "UNIX_SYS OR RISCOS" OFF)
    alsa: bool, // "Support the ALSA audio API" ${UNIX_SYS})
    alsa_shared: bool = true, // "Dynamically load ALSA audio support" ON "ALSA" OFF)
    jack: bool, // "Support the JACK audio API" ${UNIX_SYS})
    jack_shared: bool = true, // "Dynamically load JACK audio support" ON "JACK" OFF)
    esd: bool, // "Support the Enlightened Sound Daemon" ${UNIX_SYS})
    esd_shared: bool = true, // "Dynamically load ESD audio support" ON "ESD" OFF)
    pulseaudio: bool, // "Use PulseAudio" ${UNIX_SYS})
    pulseaudio_shared: bool = true, // "Dynamically load PulseAudio support" ON "PULSEAUDIO" OFF)
    arts: bool, // "Support the Analog Real Time Synthesizer" ${UNIX_SYS})
    arts_shared: bool = true, // "Dynamically load aRts audio support" ON "ARTS" OFF)
    nas: bool, // "Support the NAS audio API" ${UNIX_SYS})
    nas_shared: bool = true, // "Dynamically load NAS audio API" ${UNIX_SYS})
    sndio: bool, // "Support the sndio audio API" ${UNIX_SYS})
    fusionsound: bool = false, // "Use FusionSound audio driver" OFF)
    fusionsound_shared: bool = true, // "Dynamically load fusionsound audio support" ON "FUSIONSOUND" OFF)
    libsamplerate: bool, // "Use libsamplerate for audio rate conversion" ${UNIX_SYS})
    libsamplerate_shared: bool = true, // "Dynamically load libsamplerate" ON "LIBSAMPLERATE" OFF)
    rpath: bool, // "Use an rpath when linking SDL" ${UNIX_SYS})
    clock_gettime: bool = false, // "Use clock_gettime() instead of gettimeofday()" OFF)
    input_tslib: bool, // "Use the Touchscreen library for input" ${UNIX_SYS})
    video_x11: bool, // "Use X11 video driver" ${UNIX_SYS})
    video_wayland: bool, // "Use Wayland video driver" ${UNIX_SYS})
    wayland_shared: bool = true, // "Dynamically load Wayland support" ON "VIDEO_WAYLAND" OFF)
    video_wayland_qt_touch: bool = true, // "QtWayland server support for Wayland video driver" ON "VIDEO_WAYLAND" OFF)
    video_rpi: bool, // "Use Raspberry Pi video driver" ${UNIX_SYS})
    x11_shared: bool = true, // "Dynamically load X11 support" ON "VIDEO_X11" OFF)

    /// these depend on video_x11 -- TODO: improve type
    video_x11_xcursor: bool = true,
    video_x11_xinerama: bool = true,
    video_x11_xinput: bool = true,
    video_x11_xrandr: bool = true,
    video_x11_xscrnsaver: bool = true,
    video_x11_xshape: bool = true,
    video_x11_xvm: bool = true,

    video_cocoa: bool, // "Use Cocoa video driver" ${APPLE})
    directx: bool, // "Use DirectX for Windows audio/video" ${WINDOWS})
    wasapi: bool, // "Use the Windows WASAPI audio driver" ${WINDOWS})
    render_d3d: bool, // "Enable the Direct3D render driver" ${WINDOWS})
    render_metal: bool, // "Enable the Metal render driver" ${APPLE})
    video_vivante: bool, // "Use Vivante EGL video driver" ${UNIX_SYS})
    video_vulkan: bool = true, // "Enable Vulkan support" ON "ANDROID OR APPLE OR LINUX OR WINDOWS" OFF)
    video_metal: bool = true, // "Enable Metal support" ${APPLE})
    video_kmsdrm: bool, // "Use KMS DRM video driver" ${UNIX_SYS})
    kmsdrm_shared: bool = true, // "Dynamically load KMS DRM support" ON "VIDEO_KMSDRM" OFF)
    video_offscreen: bool = false, // "Use offscreen video driver" OFF)
    backgrounding_signal: ?usize = null, // "number to use for magic backgrounding signal or 'OFF'" "OFF")
    foregrounding_signal: ?usize = null, // "number to use for magic foregrounding signal or 'OFF'" "OFF")
    hidapi: bool = true, // "Use HIDAPI for low level joystick drivers" ${OPT_DEF_HIDAPI})

    sdl_static_pic: bool = true, // "Static version of the library should be built with Position Independent Code" OFF "SDL_STATIC" OFF)
    sdl_test: bool = false, // "Build the test directory" OFF)

    pub fn create(target: std.build.Target, overrides: anytype) Options {
        const unix = switch (target.os_tag orelse builtin.os.tag) {
            .linux, .freebsd, .netbsd, .openbsd, .solaris, .aix, .minix, .kfreebsd, .dragonfly => true,
            else => false,
        };

        const apple = switch (target.os_tag orelse builtin.os.tag) {
            .ios, .macos, .tvos, .watchos => true,
            else => false,
        };

        const windows = switch (target.os_tag orelse builtin.os.tag) {
            .windows => true,
            else => false,
        };

        const arch64 = (target.cpu_arch orelse builtin.cpu.arch).ptrBitWidth() == 64;
        const arm = (target.cpu_arch orelse builtin.cpu.arch).isARM();
        const riscos = (target.cpu_arch orelse builtin.cpu.arch).isRISCV();
        const ssemath = apple or arch64 and !arm;
        const unix_sys = unix and !apple and !riscos;

        var options = Options{
            .ssemath = ssemath,
            .sse2 = ssemath,
            .sse3 = ssemath,
            .alsa = unix,
            .jack = unix,
            .esd = unix,
            .pulseaudio = unix,
            .arts = unix,
            .nas = unix,
            .sndio = unix,
            .libsamplerate = unix,
            .rpath = unix,
            .input_tslib = unix,
            .video_x11 = unix,
            .video_wayland = unix,
            .video_rpi = unix,
            .video_cocoa = apple,
            .directx = windows,
            .wasapi = windows,
            .render_d3d = windows,
            .render_metal = apple,
            .video_vivante = unix,
            .video_kmsdrm = unix,
        };

        for (std.meta.fields(@TypeOf(overrides))) |field| {
            @field(options, field.name) = @field(overrides, field.name);
        }

        return options;
    }
};

const general_srcs = &[_][]const u8{
    "src/*.c",
    "src/atomic/*.c",
    "src/audio/*.c",
    "src/cpuinfo/*.c",
    "src/dynapi/*.c",
    "src/events/*.c",
    "src/file/*.c",
    "src/libm/*.c",
    "src/render/*.c",
    "src/render/*/*.c",
    "src/stdlib/*.c",
    "src/thread/*.c",
    "src/timer/*.c",
    "src/video/*.c",
    "src/video/yuv2rgb/*.c",
};

const minimal_srcs = &[_][]const u8{
    "src/SDL_assert.c",
    "src/SDL.c",
    "src/SDL_dataqueue.c",
    "src/SDL_error.c",
    "src/SDL_hints.c",
    "src/SDL_log.c",
    "src/audio/SDL_audio.c",
    "src/audio/SDL_audiocvt.c",
    "src/audio/SDL_audiodev.c",
    "src/audio/SDL_audiotypecvt.c",
    "src/audio/SDL_mixer.c",
    "src/audio/SDL_wave.c",
    "src/audio/dummy/SDL_dummyaudio.c",
    "src/cpuinfo/SDL_cpuinfo.c",
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
    "src/haptic/dummy/SDL_syshaptic.c",
    "src/joystick/SDL_gamecontroller.c",
    "src/joystick/SDL_joystick.c",
    "src/joystick/dummy/SDL_sysjoystick.c",
    "src/loadso/dummy/SDL_sysloadso.c",
    "src/power/SDL_power.c",
    "src/filesystem/dummy/SDL_sysfilesystem.c",
    "src/render/SDL_d3dmath.c",
    "src/render/SDL_render.c",
    "src/render/SDL_yuv_sw.c",
    "src/render/software/SDL_blendfillrect.c",
    "src/render/software/SDL_blendline.c",
    "src/render/software/SDL_blendpoint.c",
    "src/render/software/SDL_drawline.c",
    "src/render/software/SDL_drawpoint.c",
    "src/render/software/SDL_render_sw.c",
    "src/render/software/SDL_rotate.c",
    "src/sensor/SDL_sensor.c",
    "src/sensor/dummy/SDL_dummysensor.c",
    "src/stdlib/SDL_getenv.c",
    "src/stdlib/SDL_iconv.c",
    "src/stdlib/SDL_malloc.c",
    "src/stdlib/SDL_qsort.c",
    "src/stdlib/SDL_stdlib.c",
    "src/stdlib/SDL_string.c",
    "src/stdlib/SDL_strtokr.c",
    "src/thread/SDL_thread.c",
    "src/thread/generic/SDL_syscond.c",
    "src/thread/generic/SDL_sysmutex.c",
    "src/thread/generic/SDL_syssem.c",
    "src/thread/generic/SDL_systhread.c",
    "src/thread/generic/SDL_systls.c",
    "src/timer/SDL_timer.c",
    "src/timer/dummy/SDL_systimer.c",
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
    "src/video/dummy/SDL_nullevents.c",
    "src/video/dummy/SDL_nullframebuffer.c",
    "src/video/dummy/SDL_nullvideo.c",
};
