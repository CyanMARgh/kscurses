demo_6 :: () {
	group : UI_Group;
		text_buf : UI_Text_Buf;
		line_input : UI_Line_Input;
	init(*line_input); defer deinit(*line_input);
	lines : [..]string;
	defer {
		for lines {
			free(it);
		}
		array_free(lines);
	}
	set_sub_elements(*group,
		.{*line_input, .{20, 3, 0, 0}},
		.{*text_buf, .{20, 20, 0, 3}}
	);
	link_tb(*line_input, *text_buf);
	set_main_scene(.{*group, *line_input});

	struct_lambda(#code {line_input.extra_handler; line_input; lines; text_buf; (key : Key)->(bool); {
		if key == .ENTER {
			str := get_string(_line_input);
			reset(_line_input);
			array_add(_lines, str);
			_text_buf.lines = <<_lines;
			return true;
		}
		return false;
	}});
	struct_lambda(#code {text_buf.extra_handler; lines; text_buf; (key : Key)->(bool); {
		if key == .ENTER && _lines.count > 0 {
			str := pop(_lines);
			free(str);
			_text_buf.lines = <<_lines;
			return true;
		}
		return false;
	}});


	use_ks_curses();
	run_singlethread_ui();
	// run_multithread_ui();
}