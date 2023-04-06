demo_3 :: () {
	on_resize := () {
		builder := String_Builder.{allocator = temp};
		resize_clear(*canvas, Ibox2.{size = terminal_state.size});
		// c_fill(*canvas, make_char(#char"@", foreground = .BRIGHT_YELLOW, background = .BLACK));
		c_fill(*canvas, fill_function);
		c := make_char(#char"@", foreground = .BRIGHT_YELLOW, background = .BLACK);

		b_draw_canvas(*builder, *canvas);
		c_putchar(*canvas, c, .{1, 1});
		c_putchar(*canvas, c, .{2, 2});
		c_putchar(*canvas, c, .{3, 3});
		b_draw_canvas(*builder, *canvas);

		ks_write(builder_to_string(*builder, allocator = temp));
		reset_temporary_storage();
	};
	terminal_state.on_resize = on_resize;

	use_ks_curses();
	on_resize();

	// while 1 {
	// 	arr := NewArray(100000, int);
	// 	assert(xx arr.data);
	// 	array_free(arr);
	// }

	defer deinit(*canvas);

	input := ks_getch();

	// refresh_all :: () {
	// 	using terminal_state;
	// 	ks_clear_screen();
	// 	resize_no_fill(*main_window, .{size=size});
	// 	fill(*main_window, fill_function);
	// 	refresh(*main_window);
	// };
	// terminal_state.on_resize = refresh_all;

	// use_ks_curses();

	// defer clear(main_window);

	// input := ks_getch();
}

#scope_file

canvas : Canvas;

// main_window : Window;

fill_function :: (coord : ivec2, zone : Ibox2) -> Char {
	size := zone.size;
	return find_best_char(.{
		xx (coord.x * 255 / (size.x - 1)),
		xx (coord.y * 255 / (size.y - 1)),
		0
	});
}
find_best_char :: (p : u8vec3) -> Char {
	r6 := cast(u16)p.x * 6 / 256;
	g6 := cast(u16)p.y * 6 / 256;
	b6 := cast(u16)p.z * 6 / 256;

	x := 16 + 36 * r6 + 6 * g6 + b6;
	return make_char(
		utf8(" "),
		background = .COLOR256,
		bcol256 = cast(u8)x 
	);
}