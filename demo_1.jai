//TODO fix thread errors

demo_1 :: () {
	init(*win_mtx);
	init(*buf_mtx);
	
	plm = create_with_filename("clip.mpg");
	if !plm {
		print("Couldn't open video\n");
		return;
	}
	set_audio_enabled(plm, false);
	w, h := get_size(plm); video_size = .{w, h};
	rgb_buffer = NewArray(w * h, u8vec3); defer array_free(rgb_buffer);		
	defer plm_destroy(plm);

	update_frame :: () {
		if !video_runs return;
		defer frame_id += 1;
		frame := decode_video(plm);
		if !frame {
			video_runs = false;
			return;
		}
		frame_to_rgb(frame, xx rgb_buffer.data, video_size.x * 3);
	}
	fill_function :: (coord : ivec2, zone : Ibox2) -> Char {
		_x, _y := coord.x * (video_size.x - 1) / zone.width, coord.y * (video_size.y - 1) / zone.height;
		pixel := rgb_buffer[_y * video_size.x + _x];
		return find_best_char(pixel, true/*coord.x * 2 < size.x*/);
	}
	update_frame();

	refresh_all :: () {
		using terminal_state;
		resize_clear(*main_canvas, .{size = size});
		// resize_no_fill(*main_window, .{size=size});
		c_fill(*main_canvas, fill_function);
		ks_draw_canvas(*main_canvas);
		if !video_runs ks_print(.{2, 2}, make_graphics_mode(foreground = .BLACK, background = .GREEN), "press any key to exit.");
	}
	
	{
		use_ks_curses();
			
		defer {
			lock(*buf_mtx); defer unlock(*buf_mtx);
			deinit(*main_canvas);
		}

		render_cycle :: (thread : *Thread) -> s64 {
			using terminal_state;
			t0 := to_milliseconds(current_time_monotonic());
			while video_runs && !forced_exit {
				ti := to_milliseconds(current_time_monotonic());
				{
					lock(*buf_mtx); defer unlock(*buf_mtx);
					update_frame();
					refresh_all();
				}
				delta := (frame_id * 1000 / FPS) - (ti - t0);
				if delta > 0 sleep_milliseconds(xx delta);
			}
			return 0;
		}
		render_thread : Thread;
		thread_init(*render_thread, render_cycle);
		defer thread_deinit(*render_thread);
		thread_start(*render_thread);

		while 1 {
			c := ks_getch(block = false);
			if c != .READ_ERROR break;	
			lock(*buf_mtx); defer unlock(*buf_mtx);
			refresh_all();
		}

		forced_exit = true;
		while !thread_is_done(*render_thread) { }
	}
}

#scope_file
#import "stb_image_write";
#import "pl_mpeg";
#import "Thread";

plm : *Plm;

find_best_char :: (_p : u8vec3, use_mix : bool) -> Char {
	p := cast_vec(s32, _p);
	to_6level :: (x : s32) -> u8, s32 {
		if x < 44 {
			return 0, 0;
		} else if x < 112 {
			return 1, 87;
		} else if x < 156 {
			return 2, 135;
		} else if x < 196 {
			return 3, 175;
		} else if x < 236 {
			return 4, 215;
		} else {
			return 5, 255;
		}
	}
	to_6level :: (v : ivec3) -> u8vec3, ivec3 {
		ix, hx := to_6level(v.x);
		iy, hy := to_6level(v.y);
		iz, hz := to_6level(v.z);
		return .{ix, iy, iz}, .{hx, hy, hz};
	}
	col_code :: (v : u8vec3) -> u8 {
		return 16 + 36 * v.x + 6 * v.y + v.z;
	}
	a6, a256 := to_6level(p);
	b6, b256 := to_6level(p * 2 - a256);

	if use_mix {
		return make_char(
			utf8("▒"),
			foreground = .COLOR256,
			background = .COLOR256,
			fcol256 = col_code(b6),
			bcol256 = col_code(a6)
		);
	} else {
		return make_char(
			utf8(" "),
			background = .COLOR256,
			bcol256 = col_code(a6)
		);
	}
}
rgb_buffer : []u8vec3;
buf_mtx : Mutex;

video_size : ivec2;
frame_id := 0;
video_runs := true;
forced_exit := false;

FPS :: 25;

main_canvas : Canvas;
win_mtx : Mutex;
