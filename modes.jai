MAX_ATTRS :: 5;
Graphics_Mode :: struct {
	foreground : u8;
	background : u8;
	attrs : [MAX_ATTRS]bool;
	fcol256 : u8;
	bcol256 : u8;
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
	COLOR256		:: 38;

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
	if foreground != prev.foreground || fcol256 != prev.fcol256 {
		if foreground != xx Color.COLOR256 {
			print_to_builder(builder, "\e[%m", foreground);
		} else {
			print_to_builder(builder, "\e[38;5;%m", fcol256);			
		}
	}
	if background != prev.background || bcol256 != prev.bcol256 {
		if background != xx Color.COLOR256 + 10 {
			print_to_builder(builder, "\e[%m", background);
		} else {
			print_to_builder(builder, "\e[48;5;%m", bcol256);
		}
	}
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

make_graphics_mode :: (foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, strikethrough := false, fcol256 :u8= 0, bcol256 :u8= 0) -> Graphics_Mode {
	result : Graphics_Mode = ---;

	result.foreground = xx foreground;
	result.background = xx (background + 10);
	result.attrs[0] = bold;
	result.attrs[1] = dim;
	result.attrs[2] = italic;
	result.attrs[3] = underline;
	result.attrs[4] = strikethrough;
	result.fcol256 = fcol256;
	result.bcol256 = bcol256;

	return result;
}
make_char :: (code : u64, foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, strikethrough := false, fcol256 :u8= 0, bcol256 :u8= 0) -> Char {
	return .{code, make_graphics_mode(foreground, background, bold, dim, italic, underline, strikethrough, fcol256, bcol256)};
}
length :: (c : Char) -> u8 {
	for 0..7 if !c.codes[it] return xx it;
	return 8;
}
