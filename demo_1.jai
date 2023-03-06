demo_1 :: () {
	init(*win_mtx);
	init(*buf_mtx);
	{
		plm = create_with_filename("clip.mpg");
		if !plm {
			print("Couldn't open video\n");
			return;
		}
		set_audio_enabled(plm, false);
		w, h := get_size(plm); video_size = .{w, h};
		rgb_buffer = NewArray(w * h, Pixel); defer array_free(rgb_buffer);		
	}

	update_frame :: () {
		lock(*buf_mtx); defer unlock(*buf_mtx);
		if !video_runs return;
		defer frame_id += 1;
		frame := decode_video(plm);
		if !frame {
			video_runs = false;
			return;
		}
		frame_to_rgb(frame, xx rgb_buffer.data, video_size.x * 3);
	}
	fill_function :: (coord : ivec2, size : ivec2) -> Char {
		_x, _y := coord.x * (video_size.x - 1) / size.x, coord.y * (video_size.y - 1) / size.y;
		pixel := rgb_buffer[_y * video_size.x + _x];
		return find_best_char(pixel);
	}
	update_frame();

	refresh_all :: () {
		lock(*win_mtx);
			using terminal_state;
			resize_no_fill(*main_window, .{width=size_x, height=size_y});
			lock(*buf_mtx);
				fill(*main_window, fill_function);
			unlock(*buf_mtx);
			refresh(*main_window);
			if !video_runs ks_print(.{2, 2}, make_graphics_mode(foreground = .BLACK, background = .GREEN), "press any key to exit.");
		unlock(*win_mtx);
	}

	terminal_state.on_resize = refresh_all;
	{
		use_ks_curses();
			
		defer clear(main_window);

		render_cycle :: (thread : *Thread) -> s64 {
			using terminal_state;
			t0 := to_milliseconds(current_time_monotonic());
			while video_runs && !forced_exit {
				ti := to_milliseconds(current_time_monotonic());
				update_frame();
				refresh_all();
				delta := (frame_id * 1000 / FPS) - (ti - t0);
				if delta > 0 sleep_milliseconds(xx delta);
			}
			return 0;
		}
		render_thread : Thread;
		thread_init(*render_thread, render_cycle);
		defer thread_deinit(*render_thread);
		thread_start(*render_thread);

		c := ks_getch();
		forced_exit = true;
		while !thread_is_done(*render_thread) { }
	}
}

#scope_file
#import "stb_image_write";
#import "pl_mpeg";
#import "Thread";

plm : *Plm;
Pixel :: struct { r, g, b : u8; }
COLOR_CODES :: Pixel.[
	.{0x17, 0x14, 0x21},
	.{0xC0, 0x1C, 0x28},
	.{0x26, 0xA2, 0x69},
	.{0xA2, 0x73, 0x4C},
	.{0x12, 0x48, 0x8B},
	.{0xA3, 0x47, 0xBA},
	.{0x2A, 0xA1, 0xB3},
	.{0xD0, 0xCF, 0xCC},
	.{0x5E, 0x5C, 0x64},
	.{0xF6, 0x61, 0x51},
	.{0x33, 0xDA, 0x7A},
	.{0xE9, 0xAD, 0x0C},
	.{0x2A, 0x7B, 0xDE},
	.{0xC0, 0x61, 0xCB},
	.{0x33, 0xC7, 0xDE},
	.{0xFF, 0xFF, 0xFF}
];
mix :: (p1 : Pixel, p2 : Pixel, m : float) -> Pixel {
	mix :: (x : u8, y : u8, m : float) -> u8 {
		return cast(u8)(cast(float) x + m * cast(float) (y - x));
	}
	return .{mix(p1.r, p2.r, m), mix(p1.g, p2.g, m), mix(p1.b, p2.b, m)};
}

find_best_char :: (p : Pixel) -> Char {
	r6 := cast(u16)p.r * 6 / 256;
	g6 := cast(u16)p.g * 6 / 256;
	b6 := cast(u16)p.b * 6 / 256;

	x := 16 + 36 * r6 + 6 * g6 + b6;
	return make_char(
		#char" ",
		background = .COLOR256,
		bcol256 = cast(u8)x 
	);
}
rgb_buffer : []Pixel;
buf_mtx : Mutex;

video_size : ivec2;
frame_id := 0;
video_runs := true;
forced_exit := false;

// FRAME_COUNT :: 5468;
// LENGTH_MS :: (3 * 60 + 39) * 1000;
FPS :: 25;

main_window : Window;
win_mtx : Mutex;
