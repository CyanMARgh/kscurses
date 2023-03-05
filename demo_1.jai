demo_1 :: () {
	init(*win_mtx);
	init(*buf_mtx);
	{
		plm = create_with_filename("hmm.mpg");
		if !plm {
			print("Couldn't open file (hmm.mpg)\n");
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
		if !frame /*|| frame_id > 300*/ {
			video_runs = false;
			return;
		}
		frame_to_rgb(frame, xx rgb_buffer.data, video_size.x * 3);
	}
	fill_function :: (coord : ivec2, size : ivec2) -> Char {
		_x, _y := coord.x * (video_size.x - 1) / size.x, coord.y * (video_size.y - 1) / size.y;
		pixel := rgb_buffer[_y * video_size.x + _x];
		br := (cast(u64)pixel.r + pixel.g + pixel.b) / 3;
		return make_char(#char" ", background = ifx br < 127 Color.BLACK else .BRIGHT_WHITE);
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
	use_ks_curses();
		
	defer clear(main_window);

	render_cycle :: (thread : *Thread) -> s64 {
		using terminal_state;
		while video_runs && !forced_exit {
			sleep_milliseconds(31);
			update_frame();
			refresh_all();
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

#scope_file
#import "stb_image_write";
#import "pl_mpeg";
#import "Thread";

plm : *Plm;
Pixel :: struct { r, g, b : u8; }
rgb_buffer : []Pixel;
buf_mtx : Mutex;

video_size : ivec2;
frame_id := 0;
video_runs := true;
forced_exit := false;

main_window : Window;
win_mtx : Mutex;
