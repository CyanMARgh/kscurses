DEBUG :: false;
ENABLE_SIGINT :: true;
ENABLE_SIGTERM :: true;
ENABLE_SIGKILL :: true;
ESCAPE_EXIT :: false;

#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import "POSIX";
#import "Process";
#import "String";

#assert OS == .LINUX;

#load "ks_print.jai";
#load "resize.jai";
#load "init.jai";
#load "ivec.jai";

MAX_ATTRS :: 5;
Graphics_Mode :: struct {
	foreground : u8;
	background : u8;
	attrs : [MAX_ATTRS]bool;
	// 0 - bold (on/off/keep)
	// 1 - dim/faint
	// 2 - italic
	// 3 - underline
	// 4 - strikethrough (?)
}
Char :: struct {
	code : u64;
	#place code;
	codes : [8]u8;
	using mode : Graphics_Mode;
}
Color :: enum u8 {
	RESET 			:: 0;
	DEFAULT 		:: 39;

	BLACK 			:: 30;
	RED 			:: 31;
	GREEN 			:: 32;
	YELLOW 			:: 33;
	BLUE 			:: 34;
	MAGENTA 		:: 35;
	CYAN 			:: 36;
	WHITE 			:: 37;

	BRIGHT_BLACK 	:: 90;
	BRIGHT_RED 		:: 91;
	BRIGHT_GREEN 	:: 92;
	BRIGHT_YELLOW 	:: 93;
	BRIGHT_BLUE 	:: 94;
	BRIGHT_MAGENTA 	:: 95;
	BRIGHT_CYAN 	:: 96;
	BRIGHT_WHITE 	:: 97;
}
b_mode_difference :: (builder : *String_Builder, prev : Graphics_Mode, using current : Graphics_Mode) {
	add_attr_code :: (builder : *String_Builder, prev : bool, current : bool, on_code : u8) { 
		if prev != current {
			print_to_builder(builder, "\e[%m", ifx current on_code else on_code + 20); 
		}
	}
	if foreground != prev.foreground print_to_builder(builder, "\e[%m", foreground);
	if background != prev.background print_to_builder(builder, "\e[%m", background);
	add_attr_code(builder, prev.attrs[0], attrs[0], 1);
	add_attr_code(builder, prev.attrs[1], attrs[1], 2);
	add_attr_code(builder, prev.attrs[2], attrs[2], 3);
	add_attr_code(builder, prev.attrs[3], attrs[3], 4);
	add_attr_code(builder, prev.attrs[4], attrs[4], 9);
}

b_mode_set :: (builder : *String_Builder, using mode : Graphics_Mode) {
	add_attr_code :: (builder : *String_Builder, current : bool, on_code : u8) { 
		print_to_builder(builder, "\e[%m", ifx current on_code else on_code + 20); 
	}
	print_to_builder(builder, "\e[%m", foreground);
	print_to_builder(builder, "\e[%m", background);
	add_attr_code(builder, attrs[0], 1);
	add_attr_code(builder, attrs[1], 2);
	add_attr_code(builder, attrs[2], 3);
	add_attr_code(builder, attrs[3], 4);
	add_attr_code(builder, attrs[4], 9);
}
t_mode_set :: (mode : Graphics_Mode) -> string {
	builder := String_Builder.{allocator = temp};
	return builder_to_string(*builder, temp);
}

make_graphics_mode :: (foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, strikethrough := false) -> Graphics_Mode {
	result : Graphics_Mode = ---;

	result.foreground = xx foreground;
	result.background = xx (background + 10);
	result.attrs[0] = bold;
	result.attrs[1] = dim;
	result.attrs[2] = italic;
	result.attrs[3] = underline;
	result.attrs[4] = strikethrough;

	return result;
}
make_char :: (code : u64, foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, strikethrough := false) -> Char {
	return .{code, make_graphics_mode(foreground, background, bold, dim, italic, underline, strikethrough)};
}
length :: (c : Char) -> u8 {
	for 0..7 if !c.codes[it] return xx it;
	return 8;
}

Window :: struct {
	using zone : Ibox2;
	chars : []Char; 
}
clear :: (w : Window) {
	array_free(w.chars);
}
print_string_size : s64;
refresh :: (using w : *Window) {
	print_string_size = 0;
	
	builder := String_Builder.{allocator=temp};
	pix_id : u32 = 0;
	for y : 0..height-1 {
		prev_mode : Graphics_Mode; // TODO ???
		b_move_cursor(*builder, ivec2.{0, y} + corner);
		for x : 0..width-1 {
			C := chars[pix_id];
			b_mode_difference(*builder, prev_mode, C.mode);
			prev_mode = C.mode;
			char_str : string;
			char_str.data = xx *(C.code);
			char_str.count = length(C);
			append(*builder, char_str);
			pix_id += 1;
		}
		b_esc_m(*builder, 0);
	}
	str := builder_to_string(*builder, temp);
	print_string_size = str.count;
	ks_write(str);
	reset_temporary_storage();
}
make_window :: (_zone : Ibox2) -> Window {
	using w := Window.{zone = _zone};
	chars = NewArray(height * width, Char);
	return w;
}
fill :: (using w : *Window, fill_function : (coord : ivec2, size : ivec2) -> Char) {
	pix_id : u32 = 0;
	for y : 0..height-1 {
		for x : 0..width-1 {
			chars[pix_id] = fill_function(.{x, y}, size);
			pix_id += 1;
		}
	}
}
resize_no_fill :: (using w : *Window, _zone : Ibox2) {
	array_free(chars);
	zone = _zone;
	chars = NewArray(width * height, Char);
}

main_window : Window;

main :: () {
	#if DEBUG defer report_memory_leaks();
	fill_function :: (coord : ivec2, size : ivec2) -> Char {
		bx, by := coord.x < 6 || coord.x >= size.x-6, coord.y < 3 || coord.y >= size.y-3;
		if bx && by {
			return make_char(#char "*",
				foreground = .RED,
				background = .BRIGHT_RED
			);
		} else if bx || by {
			return make_char(
				#char " ",
				background = ifx (coord.x / 2 + coord.y) % 2 Color.BLACK else .BRIGHT_BLACK
			);
		} else {
			return make_char(
				#char "@", 
				foreground = ifx coord.x * 2 < size.x Color.GREEN else .BRIGHT_GREEN,
				background = .BLACK,
				dim = coord.y * 2 < size.y,
				strikethrough = true
			);
		}
	}
	terminal_state.on_resize = () {
		using terminal_state;
		ks_clear_screen();
		resize_no_fill(*main_window, .{width=size_x, height=size_y});
		fill(*main_window, fill_function);
		refresh(*main_window);
		ks_print(.{8, 4}, make_graphics_mode(background = .BLACK), "screen string size = %", print_string_size);
		ks_print(.{8, 5}, make_graphics_mode(background = .YELLOW), "window size = % %", size_x, size_y);
	};

	use_ks_curses();

	defer clear(main_window);

	c1 := ks_getch();
}

