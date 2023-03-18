Key :: enum u64 {
	UP				:: 0x415B1B;
	DOWN			:: 0x425B1B;
	RIGHT			:: 0x435B1B;
	LEFT			:: 0x445B1B;

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
	CTRL_Z			:: 0x1A;

	// ALT_SHIFT_UP	:: 0x4133_3b315b1b;
	// ALT_SHIFT_DOWN	:: 0x4233_3b315b1b;
	// ALT_SHIFT_RIGHT	:: 0x4333_3b315b1b;
	// ALT_SHIFT_LEFT	:: 0x4433_3b315b1b;

	ENTER			:: 0x0D;
	ESCAPE			:: 0x1B;
	BACKSPACE		:: 0x7F;
	DELETE			:: 0x7E335B1B;
}
ks_getch :: () -> Key {
	buf : u64 = 0;
	// still not sure is it proper way to read key-by-key
	// but not noticed any bugs now 
	while 1 {
		l := read(STDIN_FILENO, (cast(*u8)*buf), 8);
		if l > 0 break;
	}
	get_exit_code :: inline (code : u64) -> s32 {
		#if ENABLE_SIGINT if code == 3 return 130;
		#if ENABLE_SIGTERM if code == 28 return 143;
		#if ENABLE_SIGKILL if code == 28 return 137;
		return 0;
	}
	exit_code := get_exit_code(buf);
	if exit_code {
		ks_terminate();
		exit(exit_code);
	}	

	return xx buf;
}
ks_write :: (str : string) {
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