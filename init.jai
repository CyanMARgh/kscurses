init :: () {
	ks_write(tprint("%1%2%3%4", "\e[?25l", "\e7", "\e[?1047h", "\e[?30l"));
	// 1 - hide cursor
	// 2 - save cursor
	// 3 - switch to second screen
	// 4 - hide scrollbar
	run_command("stty", "raw", "-echo");// set input mode

	ks_clear_screen();
	update_terminal_size();
	enable_resize_handling();
	reset_temporary_storage();
}
terminate :: () {
	ks_write(tprint("%1%2%3", "\e[?47l", "\e8", "\e[?25h"));
	// 1 - restore first screen
	// 2 - restore cursor position
	// 3 - show cursor
	run_command("stty", "-raw", "echo"); // set normal input mode
	reset_temporary_storage();
}
use_ks_curses :: () #expand {
	init();
	`defer terminate();
}