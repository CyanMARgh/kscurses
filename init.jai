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
	set_raw_terminal_mode();

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
My_Kernel_Termios :: struct {
	c_iflag : u32;
	c_oflag : u32;
	c_cflag : u32;
	c_lflag : u32;
	c_line : u8;
	c_cc : [19]u8;
}
my_tcsetattr :: (fd : s32, optional_actions : s32, termios_p : *My_Termios) -> s32 {
	k_termios : My_Kernel_Termios;
	cmd : u64;

	if optional_actions == {
		case TCSANOW;
		cmd = TCSETS;
		case TCSADRAIN;
		cmd = TCSETSW;
		case TCSAFLUSH;
		cmd = TCSETSF;
		case;
		exit(-1);
	}

	k_termios.c_iflag = (termios_p.c_iflag) & 0x7FFFFFFF;
	k_termios.c_oflag = termios_p.c_oflag;
	k_termios.c_cflag = termios_p.c_cflag;
	k_termios.c_lflag = termios_p.c_lflag;
	// k_termios.c_line = termios_p->c_line;	????
	// k_termios.c_ispeed = termios_p->c_ispeed;
	// k_termios.c_ospeed = termios_p->c_ospeed;

	memcpy(*(k_termios.c_cc[0]), *(termios_p.c_cc[0]), 19);
    return ioctl(fd, cmd, *k_termios);
}
my_tcgetattr :: (fd : s32, termios_p : *My_Termios) -> s32 {
	k_termios : My_Kernel_Termios;
	retval : s32;
	retval = ioctl(fd, TCGETS, *k_termios);

	termios_p.c_iflag = k_termios.c_iflag;
	termios_p.c_oflag = k_termios.c_oflag;
	termios_p.c_cflag = k_termios.c_cflag;
	termios_p.c_lflag = k_termios.c_lflag;
	// termios_p->c_line = k_termios.c_line;
	// termios_p->c_ispeed = k_termios.c_ispeed;
	// termios_p->c_ospeed = k_termios.c_ospeed;
	_POSIX_VDISABLE :: 0;

	memcpy(*(termios_p.c_cc[0]), *(k_termios.c_cc[0]), 19);

	memset((cast(*u8)*(termios_p.c_cc[0])) + 19, _POSIX_VDISABLE, (32 - 19));
	return retval;
}

term : My_Termios;
set_raw_terminal_mode :: () {
	my_tcgetattr(STDIN_FILENO, *term);
	term_new := term;

	term_new.c_iflag &= 0xFFFFFA14;// ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
	term_new.c_oflag &= 0xFFFFFFFE;//~OPOST;
	term_new.c_lflag &= 0xFFFF7FB4;//~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	term_new.c_cflag &= 0xFFFFFECF;//~(CSIZE | PARENB);
	term_new.c_cflag |= 0x00000030;

	my_tcsetattr(STDIN_FILENO, 0, *term_new);
}
restore_terminal_mode :: () {
	my_tcsetattr(STDIN_FILENO, 0, *term);	
}
