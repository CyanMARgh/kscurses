terminal_state : struct {
	size : ivec2;
	on_resize : () = null;

	// clipboard : []Char_Type;
	cursor := ivec2.{-1, -1};
	last_mode : Graphics_Mode;
}

ks_init :: () {
	ks_write(tprint("%1%2%3%4", "\e[?25l", "\e7", "\e[?1047h", "\e[?30l"));
	ks_write("\e[H");
	// 1 - hide cursor
	// 2 - save cursor
	// 3 - switch to second screen
	// 4 - hide scrollbar
	run_command("stty", "raw", "-echo");// set input mode

	ks_clear_screen();
	update_terminal_size();
	enable_resize_handling();
	// init_ui();
	reset_temporary_storage();
}
ks_terminate :: () {
	using terminal_state;
	ks_write("\e[0m");
	ks_clear_screen();
	ks_write(tprint("%1%2%3%4", "\e[?47l", "\e8", "\e[?25h", "\e[?30h"));
	// 1 - restore first screen
	// 2 - restore cursor position
	// 3 - show cursor
	// 4 - show scrolbar
	run_command("stty", "-raw", "echo"); // set normal input mode
	#if !KEEP_CLIPBOARD {
		array_free(clipboard); clipboard = .[];
		clear(*clipboard_multiline);
	}
	last_mode = .{};
	reset_temporary_storage();
}
use_ks_curses :: () #expand {
	ks_init();
	`defer ks_terminate();
}