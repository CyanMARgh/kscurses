mode_black_and_white :: #run make_graphics_mode(foreground = .BRIGHT_WHITE, background = .BLACK);

Box_Style :: struct {
	lt, rt, lb, rb, l, r, t, b, c : u32;
	mode_border, mode_space, mode_no_border := mode_black_and_white;
}

box_style_active :: Box_Style.{
	lt = #run utf8("╔"),
	rt = #run utf8("╗"),
	lb = #run utf8("╚"),
	rb = #run utf8("╝"),
	l  = #run utf8("║"),
	r  = #run utf8("║"),
	t  = #run utf8("═"),
	b  = #run utf8("═"),
	c  = #run utf8(" "),
	mode_no_border = #run make_graphics_mode(foreground = .BRIGHT_WHITE, background = .BRIGHT_BLACK)
};
box_style_passive :: Box_Style.{
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
	if border {
		c_putchar(canvas, .{code = lt, mode = mode_border}, zone.corner);
		for x : 1..zone.width-2 {
			c_putchar(canvas, .{code = t, mode = mode_border}, zone.corner + ivec2.{xx x, 0});
		}
		c_putchar(canvas, .{code = rt, mode = mode_border}, .{zone.left + zone.width - 1, zone.top});

		for y : 1..zone.height-2 {
			c_putchar(canvas, .{code = l, mode = mode_border}, .{zone.left, zone.top + y});
			for x : 1..zone.width-2 {
				c_putchar(canvas, .{code = c, mode = mode_space}, .{zone.left + x, zone.top + y});
			}
			c_putchar(canvas, .{code = r, mode = mode_border}, .{zone.left + zone.width - 1, zone.top + y});
		}

		c_putchar(canvas, .{code = lb, mode = mode_border}, .{zone.left, zone.top + zone.height - 1});
		for x : 1..zone.width-2 {
			c_putchar(canvas, .{code = b, mode = mode_border}, .{zone.left + x, zone.top + zone.height - 1});
		}
		c_putchar(canvas, .{code = rb, mode = mode_border}, zone.corner + zone.size - .{1, 1});		
	} else {
		for y : 0..zone.height-1 {
			for x : 0..zone.width-1 {
				c_putchar(canvas, .{code = c, mode = mode_no_border}, zone.corner + ivec2.{xx x, xx y});
			}
		}
	}
	return true;
}

b_box :: (builder : *String_Builder, zone : Ibox2, using charset := box_style_passive, mode := Graphics_Mode.{}, clear_center := false) {
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
t_box :: (zone : Ibox2, charset := box_style_passive, clear_center := false) -> string {
	builder := String_Builder.{allocator=temp};
	b_box(*builder, zone, charset, clear_center);
	return builder_to_string(*builder, temp); 
}
ks_box :: (zone : Ibox2, charset := box_style_passive, clear_center := false) {
	ks_write(t_box(zone, charset, clear_center));
}