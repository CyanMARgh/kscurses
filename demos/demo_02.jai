demo_02 :: () {
	defer deinit(*main_canvas);
	use_ks_curses();
	use_default_winch_handler();

	stop_main := false;
	while !stop_main {
		draw();
		reset_temporary_storage();
		key := ks_getch();
		if key == .ESCAPE stop_main = true;
	}
}

#scope_file

main_canvas : Canvas;

draw :: () {
	using terminal_state;
	// ks_mode_reset();
	// ks_clear_screen();

	resize_fill(*main_canvas, .{size = terminal_state.size}, fill_function);
	ks_draw_canvas(*main_canvas);
}
fill_function :: (coord : ivec2, zone : Ibox2) -> Char {
	return find_best_char(.{
		xx (coord.x * 255 / (zone.width - 1)),
		xx (coord.y * 255 / (zone.height - 1)),
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