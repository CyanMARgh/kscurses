Key :: enum u64 {
	READ_ERROR		:: 0xffffffff_ffffffff;

	UP				:: 0x41_5b1b;
	DOWN			:: 0x42_5b1b;
	RIGHT			:: 0x43_5b1b;
	LEFT			:: 0x44_5b1b;

	CTRL_UP 		:: 0x4135_3b315b1b;
	CTRL_DOWN 		:: 0x4235_3b315b1b;
	CTRL_RIGHT 		:: 0x4335_3b315b1b;
	CTRL_LEFT 		:: 0x4435_3b315b1b;

	SHIFT_UP		:: 0x4132_3b315b1b;
	SHIFT_DOWN		:: 0x4232_3b315b1b;
	SHIFT_RIGHT		:: 0x4332_3b315b1b;
	SHIFT_LEFT		:: 0x4432_3b315b1b;

	CTRL_SHIFT_UP	:: 0x4136_3b315b1b;
	CTRL_SHIFT_DOWN	:: 0x4236_3b315b1b;
	CTRL_SHIFT_RIGHT:: 0x4336_3b315b1b;
	CTRL_SHIFT_LEFT	:: 0x4436_3b315b1b;

	ALT_UP			:: 0x4133_3b315b1b;
	ALT_DOWN		:: 0x4233_3b315b1b;
	ALT_RIGHT		:: 0x4333_3b315b1b;
	ALT_LEFT		:: 0x4433_3b315b1b;

	CTRL_C			:: 0x03;
	CTRL_V			:: 0x16;
	CTRL_X			:: 0x18;
	CTRL_Y			:: 0x19;
	CTRL_Z			:: 0x1A;
	CTRL_BACKSLASH	:: 0x1C;

	// ALT_SHIFT_UP	:: 0x4133_3b315b1b;
	// ALT_SHIFT_DOWN	:: 0x4233_3b315b1b;
	// ALT_SHIFT_RIGHT	:: 0x4333_3b315b1b;
	// ALT_SHIFT_LEFT	:: 0x4433_3b315b1b;

	ENTER			:: 0x0D;
	ESCAPE			:: 0x1B;
	BACKSPACE		:: 0x7F;
	DELETE			:: 0x7E335B1B;
}
ks_getch :: (block := true) -> Key {
	buf : Key = xx 0;
	l := read(STDIN_FILENO, (cast(*u8)*buf), 8); //!!!
	check_signal :: inline (key : Key) {
		#if ENABLE_SIGINT if key == .CTRL_C raise(SIGINT); //!!!
		#if ENABLE_SIGQUIT if key == .CTRL_BACKSLASH raise(SIGQUIT);
	}
	check_signal(buf);
	return ifx l <= 0 then Key.READ_ERROR else buf;
}
ks_write :: (str : string) {
	printed := 0;
	// while 1 {
		r := write(STDIN_FILENO, str.data + printed, xx (str.count - printed));
		// if printed + r == str.count {
		// 	break;
		// } else if r >= 0 {
		// 	printed += r;
		// }
	// }
	__write_counter += str.count;
}
__write_counter := 0;
write_counter_delta :: () -> int {
	result := __write_counter;
	__write_counter = 0;
	return result;
}