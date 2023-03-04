#import "Basic";
#import "POSIX";
#import "Process";
#import "String";

#assert OS == .LINUX;

ks_getch :: () -> int {
	buf := 0;
	while read(STDIN_FILENO, *buf, 1) != 1 {
	}
	return buf;
}
ks_print :: (fmt : string, extra : ..Any) {
	str := tprint(fmt, ..extra);
	printed := 0;
	while 1 {
		r := write(STDIN_FILENO, str.data + printed, xx (str.count - printed));
		if printed + r == str.count {
			break;
		} else if r >= 0 {
			printed += r;
		}
	}
}
init :: () {
	ks_print("\e7");					// save cursor
	ks_print("\e[?1047h");					// switch to second screen
	ks_print("\e[?25l"); 				// hide cursor
	run_command("stty", "raw", "-echo");// set input mode

	move_cursor(0, 0);
	clear_screen();
}
move_cursor :: (x : u16, y : u16) {
	ks_print("\e[%;%H", x + 1, y + 1);
	// ks_print("\e[H");
}
clear_screen :: () {	
	ks_print("\e[2J");
}
print_at :: (x : u16, y : u16, fmt : string, extra : ..Any) {
	move_cursor(x, y);
	ks_print(fmt, ..extra);
}

terminate :: () {
	ks_print("\e[?47l");				// restore first screen
	ks_print("\e8");					// restore cursor position
	ks_print("\e[?25h");				// show cursor
	run_command("stty", "-raw", "echo");// set normal input mode
}
esc_m :: (code : int) {
	ks_print("\e[%m", code);
}
print_scene :: () {
	for i : 0..15 {
		esc_m(ifx i < 8 then 40 + i else 100 - 8 + i);
		ks_print("  ы ");
	}
}

TIOCGWINSZ :: 0x5413;
SIGWINCH :: 0x1C;

on_resize : (sx : u16, sy : u16) = null;

enable_resize_handling :: () {
	handle_resize :: (sig : s32) #c_call {
		new_context: Context;
		push_context new_context {	
			winsize : struct {
				ws_row, ws_col, ws_xpixel, ws_ypixel : u16;
			}
			ioctl(0, TIOCGWINSZ, *winsize);
			if on_resize {
				on_resize(winsize.ws_row, winsize.ws_col);
			} else {
				print("new size = %\n", winsize);
			}
		}
	}
	act := sigaction_t.{sa_handler = handle_resize};
	set := sigset_t.{__val[0] = SIGWINCH};
	act.sa_mask = set;
	sigaction(SIGWINCH, *act, null);
}

main :: () {
	init();

	on_resize = (sx : u16, sy : u16) {
		clear_screen();
		move_cursor(3, 3);
		ks_print("size = %x%", sx, sy);
	};
	enable_resize_handling();

	c := ks_getch();

	// while 1 {}
	terminate();
	print("[[[%]]]\n", c);
}

