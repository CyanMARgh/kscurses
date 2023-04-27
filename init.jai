terminal_state : struct {
	size : ivec2;
	cursor := ivec2.{-1, -1}; // {-1, -1} if cursor hidden
	last_mode : Graphics_Mode;
}
update_terminal_size :: () {
	TIOCGWINSZ :: 0x5413;
	winsize : struct {
		ws_row, ws_col, ws_xpixel, ws_ypixel : u16;
	}
	ioctl(0, TIOCGWINSZ, *winsize);//!!!
	terminal_state.size = .{xx winsize.ws_col, xx winsize.ws_row};
}

ks_init :: () {
	__old_logger = context.logger;
	context.logger = file_logger;

	ks_write("\e[?25l");	// hide cursor
	ks_write("\e7");		// save cursor position
	ks_write("\e[?1047h");	// switch screen
	ks_write("\e[?30l");	// hide scrollbar

	ks_write("\e[H"); 		// move to top left corner
	ks_write("\e[0m");		// set default mode
	ks_write("\e[2J"); 		// clear screen
	{
		tcgetattr(STDIN_FILENO, *__term);//!!!
		term_new := __term;

		term_new.c_iflag &= 0xFFFFFA14;// ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
		term_new.c_oflag &= 0xFFFFFFFE;// ~OPOST;
		term_new.c_lflag &= 0xFFFF7FB4;// ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
		term_new.c_cflag &= 0xFFFFFECF;// ~(CSIZE | PARENB);
		term_new.c_cflag |= 0x00000030;

		tcsetattr(STDIN_FILENO, 0, *term_new);//!!!
	}
	update_terminal_size();
}
ks_terminate :: () {	
	tcsetattr(STDIN_FILENO, 0, *__term); // return echo //!!!

	ks_write("\e[?47l");	// restore screen
	ks_write("\e8");		// restore cursor
	ks_write("\e[?25h");	// show cursor
	ks_write("\e[?30h");	// show scrollbar
	terminal_state = .{};

	context.logger = __old_logger;
}
use_ks_curses :: () #expand {
	ks_init();
	`defer {
		ks_terminate();
	}
}
use_default_winch_handler :: () #expand {
	init_default_winch_handler();
	`defer deinit_default_winch_handler();
}
init_default_winch_handler :: () {
	act := sigaction_t.{
		sa_handler = (sig : s32) #c_call {
			new_context: Context;
			push_context new_context {
				update_terminal_size();
			}
		},
		sa_mask = sigset_t.{__val[0] = SIGWINCH}
	};
	sigaction(SIGWINCH, *act, null); //!!!
}
deinit_default_winch_handler :: () {
	sa : sigaction_t;
	sa.sa_handler = SIG_DFL;
	sigaction(SIGWINCH, null, *sa); //!!!
}

#scope_file
__term : My_Termios;
__old_logger : type_of(context.logger);

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

#import "File";

file_logger :: (message: string, data: *void, info: Log_Info) {
	file, ok := file_open("log.txt",for_writing=true, keep_existing_content=true);
	if !ok return;

	file_write(*file, tprint("[%] %\n", calendar_to_string(to_calendar(current_time_consensus())), message));
	file_close(*file);	
}
