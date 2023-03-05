// OS fuctions :
// read
// exit


// jai functions :
// tprint

ks_getch :: () -> s8 {
	get_exit_code :: inline (code : int) -> bool, s32 {
		#if ENABLE_SIGINT if code == 3 return true, 130;
		#if ENABLE_SIGTERM if code == 28 return true, 143;
		#if ENABLE_SIGKILL if code == 28 return true, 137;
		#if ESCAPE_EXIT if code == 27 return true, 0;
		return false, 0;
	}

	buf :s8= 0;
	while read(STDIN_FILENO, *buf, 1) != 1 { }
	should_exit, exit_code := get_exit_code(buf);
	if should_exit {
		terminate();
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
