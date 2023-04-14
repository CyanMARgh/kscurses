demo_6 :: () {
	master : UI_Master;
	line_input : UI_Line_Input;

	set_scene(*master, .{*line_input, *line_input});

	use_ks_curses();
	io_cycle(*master);
}