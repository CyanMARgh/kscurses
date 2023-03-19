ks_bell :: () {
	bell_str : string;
	bell := 7;
	bell_str.data, bell_str.count = xx *bell, 1;
	ks_write(bell_str);
}

ui_bell :: inline () {
	#if ENABLE_UI_BELL ks_bell();
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
b_cursor_set_visibility :: inline (builder : *String_Builder, $$visible : bool) {
	append(builder, ifx visible "\e[?25h" else "\e[?25l");
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


b_esc_m :: inline (builder : *String_Builder, $$code : int) {
	print_to_builder(builder, "\e[%m", code);
}
t_esc_m :: inline ($$code : int) -> string {
	return tprint("\e[%m", code);
}
ks_esc_m :: inline ($$code : int) {
	ks_write(t_esc_m(code));
}


#scope_file
b_mode_difference :: (builder : *String_Builder, prev : Graphics_Mode, using current : Graphics_Mode) {
	printed_first := false;
	add_code :: (code : u8) #expand {
		if printed_first {
			print_to_builder(builder, ";%", code);
		} else {
			print_to_builder(builder, "\e[%", code);
			printed_first = true;
		}
	}
	add_code_on_off :: (prev : bool, current : bool, on_code : Attr, off_code : Attr) #expand { 
		if prev != current add_code(xx(ifx current on_code else off_code));
	}
	if foreground != prev.foreground || fcol256 != prev.fcol256 {
		if foreground != Color.COLOR256 {
			add_code(xx foreground);
		} else {
			add_code(38); add_code(5); add_code(xx fcol256);			
		}
	}
	if background != prev.background || bcol256 != prev.bcol256 {
		if background != (Color.COLOR256 + 10) {
			add_code(xx background);
		} else {
			add_code(48); add_code(5); add_code(xx bcol256);
		}
	}
	if prev.attrs[0] != attrs[0] || prev.attrs[1] != attrs[1] {
		off0 := prev.attrs[0] && !attrs[0];
		off1 := prev.attrs[1] && !attrs[1];
		reset := off0 || off1;
		on0 := (reset || !prev.attrs[0]) && attrs[0];
		on1 := (reset || !prev.attrs[1]) && attrs[1];

		if reset add_code(xx Attr.BOLD_AND_DIM_OFF);		
		if on0 add_code(xx Attr.BOLD);
		if on1 add_code(xx Attr.DIM);
	}
	add_code_on_off(prev.attrs[2], attrs[2], .ITALIC, .ITALIC_OFF);
	add_code_on_off(prev.attrs[3], attrs[3], .UNDERLINE, .UNDERLINE_OFF);
	add_code_on_off(prev.attrs[4], attrs[4], .BLINKING, .BLINKING_OFF);
	add_code_on_off(prev.attrs[5], attrs[5], .INVERSE, .INVERSE_OFF);
	add_code_on_off(prev.attrs[6], attrs[6], .STRIKETHROUGH, .STRIKETHROUGH_OFF);
	if printed_first append(builder, "m");
}
#scope_export


b_mode_reset :: (builder : *String_Builder) {
	b_esc_m(builder, 0);
	terminal_state.last_mode = .{};
}
b_mode_set :: (builder : *String_Builder, using mode : Graphics_Mode) {
	b_mode_difference(builder, terminal_state.last_mode, mode);
	terminal_state.last_mode = mode;
}
t_mode_set :: (mode : Graphics_Mode) -> string {
	builder := String_Builder.{allocator = temp};
	b_mode_set(*builder, mode);
	return builder_to_string(*builder, temp);
}


b_putchar :: (builder : *String_Builder, c : Char) {
	b_mode_set(builder, c.mode);
	b_putchar(builder, c.code);
}

b_putchar :: inline (builder : *String_Builder, code : u64) {
	char_str : string;
	char_str.data = xx *(code);
	char_str.count = length_code(code);
	append(builder, char_str);
}
