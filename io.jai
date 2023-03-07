Keys :: enum u64 {
	UP		:: 0x415B1B;
	DOWN	:: 0x425B1B;
	RIGHT	:: 0x435B1B;
	LEFT	:: 0x445B1B;
	ENTER	:: 0x0D;
	ESCAPE	:: 0x1B;
}
ks_getch :: () -> u64 {
	buf : u64 = 0;
	byte : u8 = 0;

	get_exit_code :: inline (code : u64) -> s32 {
		#if ENABLE_SIGINT if code == 3 return 130;
		#if ENABLE_SIGTERM if code == 28 return 143;
		#if ENABLE_SIGKILL if code == 28 return 137;
		return 0;
	}
	read_byte_nonblock :: () -> s64 #expand {
		flags := fcntl(STDIN_FILENO, F_GETFL, 0);
		fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
		r := read(STDIN_FILENO, (cast(*u8)*`buf) + `byte, 1);
		fcntl(STDIN_FILENO, F_SETFL, flags);
		return r;
	}
	read_byte :: () #expand {
		while read(STDIN_FILENO, (cast(*u8)*`buf) + `byte, 1) != 1 { }
		byte += 1;
	}

	read_byte();

	#if ENABLE_ARROWS if buf == 0x1B {
		sleep_milliseconds(ESCAPE_DELAY_MS); // TODO maybe i should find better way to do it
		r := read_byte_nonblock();
		if r != 1 {
			return buf;
		}
		byte += 1;
		#if ENABLE_ARROWS if buf == 0x5B1B { // maybe there is a two-byte keyboard esc-code, but I haven't come across one yet.
			read_byte();
		}
	}

	exit_code := get_exit_code(buf);
	if exit_code {
		ks_terminate();
		exit(exit_code);
	}

	return buf;
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