demo_01 :: () {
	video_runs = true;
	stop_main = false;
	ticks = 0;

	__event_handler.proc = (e : Event, __data : *void) {
		if e.type == {
		case .KEY;
			if e.key == .ESCAPE then stop_main = true;
		case .TICK;
			ticks += 1;
			video_runs = update_main_frame();
		}
	};

	prepare(); defer finalize();

	use_ks_curses();
	use_events(tick_duration_ms = 40);

	while !stop_main {
		if wait_and_process_events() {
			draw(video_runs);
			reset_temporary_storage();
		}
	}
}
#scope_file

video_runs := true;
stop_main := false;
ticks := 0;

#import "pl_mpeg";
#import "POSIX";

plm : *Plm;
video_size : ivec2;
main_frame : []u8vec3;
main_canvas : Screen_Canvas;

prepare :: () {
	plm = create_with_filename("clip.mpg");
	if !plm {
		print("Couldn't open video\n");
		exit(1);
	}
	w, h := get_size(plm); video_size = .{w, h};
	set_audio_enabled(plm, false);
	main_frame = NewArray(w * h, u8vec3);
}
finalize :: () {
	plm_destroy(plm);
	array_free(main_frame);
	deinit(*main_canvas);
}
update_main_frame :: () -> ok:bool {
	frame_plm := decode_video(plm);
	if !frame_plm {
		array_free(main_frame);
		main_frame = .[];
		return false;
	}
	frame_to_rgb(frame_plm, xx main_frame.data, video_size.x * 3);
	return true;
}

fill_function :: (coord : ivec2, zone_size : ivec2) -> Char {
	_x, _y := coord.x * (video_size.x - 1) / zone_size.x, coord.y * (video_size.y - 1) / zone_size.y;
	pixel := ifx main_frame then main_frame[_y * video_size.x + _x] else u8vec3.{0, 0, 0};
	return find_best_char(pixel, true);
}
draw :: (video_runs : bool) {
	if video_runs {
		resize(*main_canvas, terminal_state.size);
		c_fill(*main_canvas, fill_function);
		ks_draw_canvas(*main_canvas);		
	} else {
		ks_mode_reset();
		ks_clear_screen();
		ks_print(.{2, 2}, make_graphics_mode(foreground = .BLACK, background = .GREEN), "press escape key to exit.");
	}
}