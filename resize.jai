// OS functions:
// ioctl
// sigaction

terminal_state : struct {
	size_x, size_y : u16;
	on_resize : () = null;
}
update_terminal_size :: () {
	using terminal_state;
	winsize : struct {
		ws_row, ws_col, ws_xpixel, ws_ypixel : u16;
	}
	ioctl(0, TIOCGWINSZ, *winsize);
	size_x, size_y = winsize.ws_col, winsize.ws_row;
	if on_resize on_resize();
}
enable_resize_handling :: () {
	handle_resize :: (sig : s32) #c_call {
		new_context: Context;
		push_context new_context {
			update_terminal_size();
		}
	}
	act := sigaction_t.{sa_handler = handle_resize};
	set := sigset_t.{__val[0] = SIGWINCH};
	act.sa_mask = set;
	sigaction(SIGWINCH, *act, null);
}

#scope_file

TIOCGWINSZ :: 0x5413;
SIGWINCH :: 0x1C;
