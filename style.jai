Box_Charset :: struct {
	lt, rt, lb, rb, l, r, t, b, c : u64;
}

box_charset_double_line :: Box_Charset.{
	lt = #run utf8("╔"),
	rt = #run utf8("╗"),
	lb = #run utf8("╚"),
	rb = #run utf8("╝"),
	l  = #run utf8("║"),
	r  = #run utf8("║"),
	t  = #run utf8("═"),
	b  = #run utf8("═"),
	c  = #run utf8(" ")
};
box_charset_single_line :: Box_Charset.{
	lt = #run utf8("┌"),
	rt = #run utf8("┐"),
	lb = #run utf8("└"),
	rb = #run utf8("┘"),
	l  = #run utf8("│"),
	r  = #run utf8("│"),
	t  = #run utf8("─"),
	b  = #run utf8("─"),
	c  = #run utf8(" ")
};
box_charset_default :: box_charset_single_line;

UI_Style :: struct {
	box : struct {
		default := box_charset_single_line;
		selected := box_charset_double_line;		
	}
	main_mode := #run make_graphics_mode(foreground = .WHITE, background = .BLACK);

	text : struct {
		default := #run make_graphics_mode(foreground = .WHITE, background = .BLACK);
		cursor := #run make_graphics_mode(background = .WHITE);
		selection := #run make_graphics_mode(background = .YELLOW);
		cursor_and_selection := #run make_graphics_mode(background = .BRIGHT_YELLOW);

		debug := #run make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN);
	}
}


b_box :: (builder : *String_Builder, zone : Ibox2, using charset := box_charset_default, mode := Graphics_Mode.{}, clear_center := false) {
	assert(inside(zone, terminal_state.size));
	b_move_cursor(builder, zone.corner);
	b_mode_set(builder, mode);

	b_putchar(builder, lt);
	for x : 1..zone.size.x-2 b_putchar(builder, t);
	b_putchar(builder, rt);

	for y : 1..zone.size.y-2 {
		b_move_cursor(builder, .{zone.corner.x, zone.corner.y + y});
		b_putchar(builder, l);
		if clear_center {
			for x : 1..zone.size.x-2 b_putchar(builder, c);
		} else {
			b_move_cursor(builder, .{zone.corner.x + zone.size.x - 1, zone.corner.y + y});
		}
		b_putchar(builder, r);
	}

	b_move_cursor(builder, .{zone.corner.x, zone.corner.y + zone.size.y - 1});
	b_putchar(builder, lb);
	for x : 1..zone.size.x-2 b_putchar(builder, b);
	b_putchar(builder, rb);
}
t_box :: (zone : Ibox2, charset := box_charset_default, clear_center := false) -> string {
	builder := String_Builder.{allocator=temp};
	b_box(*builder, zone, charset, clear_center);
	return builder_to_string(*builder, temp); 
}
ks_box :: (zone : Ibox2, charset := box_charset_default, clear_center := false) {
	ks_write(t_box(zone, charset, clear_center));
}