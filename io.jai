Keys :: enum u64 {
	UP		:: 0x415B1B;
	DOWN	:: 0x425B1B;
	RIGHT	:: 0x435B1B;
	LEFT	:: 0x445B1B;
	ENTER	:: 0x0D;
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
	read_byte :: () #expand {
		while read(STDIN_FILENO, (cast(*u8)*`buf) + `byte, 1) != 1 { }
		byte += 1;
	}

	read_byte();

	#if ENABLE_ARROWS || DOUBLE_ESCAPE_EXIT if buf == 0x1B {
		read_byte();
		#if DOUBLE_ESCAPE_EXIT if buf == 0x1B1B {
			ks_terminate();
			exit(0);
		}
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

ks_bell :: () {
	bell_str : string;
	bell := 7;
	bell_str.data, bell_str.count = xx *bell, 1;
	ks_write(bell_str);
}


b_move_cursor :: inline (builder : *String_Builder, coord : ivec2) {
	print_to_builder(builder, "\e[%;%H", coord.y + 1, coord.x + 1);
}
t_move_cursor :: inline (coord : ivec2) -> string {
	return tprint("\e[%;%H", coord.y, coord.x);
}
ks_move_cursor :: inline (coord : ivec2) {
	ks_write(tprint("\e[%;%H", coord.y + 1, coord.x + 1));
}


b_print :: (builder : *String_Builder, coord : ivec2, mode : Graphics_Mode, fmt : string, args : ..Any) {
	if coord != .{-1, -1} b_move_cursor(builder, coord);
	b_mode_set(builder, mode);
	print_to_builder(builder, fmt, ..args);
}
t_print :: (coord : ivec2, mode : Graphics_Mode, fmt : string, args : ..Any) -> string {
	builder := String_Builder.{allocator = temp};
	b_print(*builder, coord, mode, fmt, ..args);
	return builder_to_string(*builder, temp);
}

ks_print :: inline (coord : ivec2, mode : Graphics_Mode, fmt : string, args : ..Any) {
	ks_write(t_print(coord, mode, fmt, ..args));
}


b_clear_screen :: (builder : *String_Builder) {
	append(builder, "\e[2J");
}
t_clear_screen :: inline () -> string {
	return "\e[2J";
}
ks_clear_screen :: inline () {	
	ks_write("\e[2J");
}

b_esc_m :: inline (builder : *String_Builder, code : int) {
	print_to_builder(builder, "\e[%m", code);
}
t_esc_m :: inline (code : int) -> string {
	return tprint("\e[%m", code);
}
ks_esc_m :: inline (code : int) {
	ks_write(t_esc_m(code));
}

// coord & attrs <- optioanl params
