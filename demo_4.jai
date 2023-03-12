demo_4 :: () {
	defer {
		// array_free(input_field.line);
		clear(*input_field);
		array_free(debug_output.lines);
	}
	array_resize(*debug_output.lines, 3);
	ui_master.after_ui_upate = () => {
		l, r := selection_edges(*input_field);

		debug_output.lines[0] = tprint("l = %", l);
		debug_output.lines[1] = tprint("r = %", r);
		debug_output.lines[2] = tprint("lc = %", input_field.line.count);
	};
	set_elements(*ui_master, *input_field, *debug_output);

	terminal_state.on_resize = () => {
		ks_refresh(*ui_master);
	};

	use_ks_curses();
	io_cycle(*ui_master);
}

#scope_file

ui_master := UI_Master.{
	size_min = .{40, 20},
	size_default = .{50, 30}
};
input_field := UI_Line_Input.{
	zone_default = .{
		size = .{50, 3},
		corner = .{0, 0}
	},
	scale_mode = anchor_t
};
debug_output := UI_Text_Block.{
	zone_default = .{
		size = .{20, 5},
		corner = .{0, 3}
	}
};