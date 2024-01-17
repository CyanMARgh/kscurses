demo_07 :: () {
	bruh = .{};
	draw :: () #expand {
		ks_mode_reset();
		ks_clear_screen();
		ks_print(.{0, 0}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "ticks = %", ticks);
		ks_print(.{0, 1}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "key =   %", last_key);
		ks_print(.{0, 2}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "size =  %", terminal_state.size);
		ks_print(.{0, 3}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "event = %", last_event);
	}

	#if MULTITHREAD {
		__event_handler.proc = (e : Event, __data : *void) {
			if e.type == {
				case .KEY;
				last_key = e.key;
				case .TICK;
				ticks += 1;
			}
			last_event = e;
			if e.type == .KEY && e.key == .ESCAPE {
				stop_main = true;
			}			
		};
		use_ks_curses();
		use_events();
		while !stop_main {
			if wait_and_process_events() {
				draw();
				reset_temporary_storage();
			}
		}
	} else {
		use_ks_curses();
		use_default_winch_handler();
		while !stop_main {
			draw();
			reset_temporary_storage();
			key := ks_getch();
			if key == .ESCAPE stop_main = true;
			if key != .READ_ERROR last_key = key;
		}
	}
}
#scope_file
using bruh : struct {
	ticks := 0;
	last_key : Key;
	last_event : Event;
	stop_main := false;
	events_count := 0;
}
MULTITHREAD :: true;