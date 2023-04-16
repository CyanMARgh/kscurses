terminal_state : struct {
	size : ivec2;
	on_resize : () = null;

	// clipboard : []Char_Type;
	cursor := ivec2.{-1, -1};
	last_mode : Graphics_Mode;
}

ks_init :: () {
	ks_write("\e[?25l");	// hide cursor
	ks_write("\e7");		// save cursor position
	ks_write("\e[?1047h");	// switch screen
	ks_write("\e[?30l");	// hide scrollbar

	ks_write("\e[H"); 		// move to top left corner
	ks_write("\e[0m");		// set default mode
	ks_write("\e[2J"); 		// clear screen

	set_raw_terminal_mode();

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
	restore_terminal_mode();
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

#scope_file
// IMPORTANT
// I don't understand low-level programming, so this code is in the state of "thank god it works for me at least.".
// If something breaks for you, then most likely because of this code.
// If this happens, write to me, we will try to solve this problem together.

TCSANOW 	:: 0;
TCSADRAIN 	:: 1;
TCSAFLUSH	:: 2;
TCGETS 		:: 0x5401;
TCSETS 		:: 0x5402;
TCSETSW 	:: 0x5403;
TCSETSF		:: 0x5404;

My_Termios :: struct {
	c_iflag : u32;
	c_oflag : u32;
	c_cflag : u32;
	c_lflag : u32;
	unknown_pad : u8;
	c_cc : [32]u8;
	c_ispeed : u32;
	c_ospeed : u32;
}
libc :: #system_library "libc";
tcsetattr :: (fd : s32, optional_actions : s32, termios_p : *My_Termios) -> s32 #foreign libc;
tcgetattr :: (fd : s32, termios_p : *My_Termios) -> s32 #foreign libc;
tcflush :: (fd : s32, queue_selector : s32) -> s32 #foreign libc;
pthread_cond_wait :: (restrict_cond : *pthread_cond_t, restrict_mutex : *pthread_mutex_t) -> s32 #foreign libc;

__term : My_Termios;
// __fcntl_flags_old : s32;
set_raw_terminal_mode :: () {
	tcgetattr(STDIN_FILENO, *__term);
	term_new := __term;

	term_new.c_iflag &= 0xFFFFFA14;// ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
	term_new.c_oflag &= 0xFFFFFFFE;//~OPOST;
	term_new.c_lflag &= 0xFFFF7FB4;//~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	term_new.c_cflag &= 0xFFFFFECF;//~(CSIZE | PARENB);
	term_new.c_cflag |= 0x00000030;

	tcsetattr(STDIN_FILENO, 0, *term_new);

	// __fcntl_flags_old = fcntl(STDIN_FILENO, F_GETFL, 0);
	// fcntl(STDIN_FILENO, F_SETFL, __fcntl_flags_old | O_NONBLOCK); // make input non-blocking

	TCIFLUSH :: 0;
	tcflush(STDIN_FILENO, TCIFLUSH);
}
restore_terminal_mode :: () {
	// fcntl(STDIN_FILENO, F_SETFL, __fcntl_flags_old); // make input blocking
	// tcsetattr(STDIN_FILENO, 0, *__term);	//enable echo & buffered input

	tcsetattr(STDIN_FILENO, 0, *__term);	
}
