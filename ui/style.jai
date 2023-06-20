mode_black_and_white :: #run make_graphics_mode(foreground = .BRIGHT_WHITE, background = .BLACK);

Box_Style :: struct {
	c, tb, lr, tl, tr, bl, br, tbl, tbr, tlr, blr, tblr : u32;
	mode_border, mode_space, mode_no_border := mode_black_and_white;
}

box_style_active :: Box_Style.{
	c    = #run utf8(" "),
	tb   = #run utf8("║"),
	lr   = #run utf8("═"),
	tl   = #run utf8("╝"),
	tr   = #run utf8("╚"),
	bl   = #run utf8("╗"),
	br   = #run utf8("╔"),
	tbl  = #run utf8("╣"),
	tbr  = #run utf8("╠"),
	tlr  = #run utf8("╩"),
	blr  = #run utf8("╦"),
	tblr = #run utf8("╬"),
	mode_no_border = #run make_graphics_mode(foreground = .BRIGHT_WHITE, background = .BRIGHT_BLACK)
};
box_style_passive :: Box_Style.{
	c    = #run utf8(" "),
	tb   = #run utf8("│"),
	lr   = #run utf8("─"),
	tl   = #run utf8("┘"),
	tr   = #run utf8("└"),
	bl   = #run utf8("┐"),
	br   = #run utf8("┌"),
	tbl  = #run utf8("┤"),
	tbr  = #run utf8("├"),
	tlr  = #run utf8("┴"),
	blr  = #run utf8("┬"),
	tblr = #run utf8("┼")
};

UI_Style :: struct {
	box : struct {
		default := box_style_passive;
		cursor := box_style_active;
	}

	mode_main := mode_black_and_white;

	text : struct {
		default := mode_black_and_white;
		cursor := #run make_graphics_mode(background = .BRIGHT_BLACK);
		selection := #run make_graphics_mode(background = .YELLOW);
		cursor_and_selection := #run make_graphics_mode(background = .BRIGHT_YELLOW);

		debug := #run make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN);
	}
}

c_box :: (canvas : *Canvas, zone : Ibox2, using box_style : Box_Style, border := true) -> bool {
	if !inside(ifx border then ivec2.{2, 2} else ivec2.{0, 0}, zone.size) return false;
	assert(inside(zone, canvas.zone));
	charset : [9]u32;
	if border {
		charset[0], charset[1], charset[2], charset[3], charset[4], charset[5], charset[6], charset[7], charset[8] = br, lr, bl, tb, c, tb, tr, lr, tl;
	} else {
		charset[0], charset[1], charset[2], charset[3], charset[4], charset[5], charset[6], charset[7], charset[8] = c, c, c, c, c, c, c, c, c;
	}

	for y : 0..zone.height-1 {
		yi := ifx y == 0 then 0 else ifx y == zone.height - 1 then 2 else 1;
		for x : 0..zone.width-1 {
			xi := ifx x == 0 then 0 else ifx x == zone.width - 1 then 2 else 1;
			i := yi * 3 + xi;
			c_putchar(canvas, .{code = charset[i], mode = mode_border}, zone.corner + ivec2.{xx x, xx y});
		}
	}
	return true;
}

b_box :: (builder : *String_Builder, zone : Ibox2, using charset := box_style_passive, mode := Graphics_Mode.{}, clear_center := true) {
	assert(inside(zone, terminal_state.size));

	charset : [9]u32;
	if border {
		charset = .[br, lr, bl, tb, c, tb, tr, lr, tl];
	} else {
		charset = .[c, c, c, c, c, c, c, c, c];
	}

	b_move_cursor(builder, zone.corner);
	b_mode_set(builder, mode);

	for y : 0..zone.height-1 {
		yi := ifx y == 0 then 0 else ifx y == zone.height - 1 then 2 else 1;
		b_move_cursor(builder, .{zone.corner.x, zone.corner.y + y});

		if !clear_center && yi == 1 {
			b_putchar(builder, charset[3]);
			b_move_cursor(builder, .{zone.corner.x + zone.width - 1, zone.corner.y + y});
			b_putchar(builder, charset[5]);
		} else {
			for x : 0..zone.width-1 {
				xi := ifx x == 0 then 0 else ifx x == zone.width - 1 then 2 else 1;
				i := yi * 3 + xi;
				b_putchar(builder, charset[i]);
			}			
		}

	}
}
t_box :: (zone : Ibox2, charset := box_style_passive, clear_center := false) -> string {
	builder := String_Builder.{allocator=temp};
	b_box(*builder, zone, charset, clear_center);
	return builder_to_string(*builder, temp); 
}
ks_box :: (zone : Ibox2, charset := box_style_passive, clear_center := false) {
	ks_write(t_box(zone, charset, clear_center));
}
