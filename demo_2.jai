demo_2 :: () {
	#if DEBUG defer report_memory_leaks();
	fill_function :: (coord : ivec2, size : ivec2) -> Char {
		return find_best_char(.{
			xx (coord.x * 255 / (size.x - 1)),
			xx (coord.y * 255 / (size.y - 1)),
			0
		});
	}
	refresh_all :: () {
		using terminal_state;
		ks_clear_screen();
		resize_no_fill(*main_window, .{width=size_x, height=size_y});
		fill(*main_window, fill_function);
		refresh(*main_window);
	};
	terminal_state.on_resize = refresh_all;

	use_ks_curses();
	defer clear(main_window);

	input := ks_getch();
}

#scope_file

main_window : Window;

Pixel :: struct { 
	r, g, b : u8;
}
find_best_char :: (p : Pixel) -> Char {
	r6 := cast(u16)p.r * 6 / 256;
	g6 := cast(u16)p.g * 6 / 256;
	b6 := cast(u16)p.b * 6 / 256;

	x := 16 + 36 * r6 + 6 * g6 + b6;
	return make_char(
		#char" ",
		background = .COLOR256,
		bcol256 = cast(u8)x 
	);
}