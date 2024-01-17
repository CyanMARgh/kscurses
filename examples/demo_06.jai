demo_06 :: () {
	init(*line_input); defer deinit(*line_input);
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

	line_input.extra_handler.proc = (key : Key, __data : *void) -> bool {
		if key == .ENTER {
			str := get_string(*line_input);
			reset(*line_input);
			array_add(*lines, str);
			text_buf.lines = lines;
			return true;
		}
		return false;		
	};

	text_buf.extra_handler.proc = (key : Key, __data : *void) -> bool {
		if key == .ENTER && lines.count > 0 {
			str := pop(*lines);
			free(str);
			text_buf.lines = lines;
			return true;
		}
		return false;		
	};

	use_ks_curses();
	run_singlethread_ui();
	// run_multithread_ui();
}

#scope_file
group : UI_Group;
	text_buf : UI_Text_Buf;
	line_input : UI_Line_Input;
lines : [..]string;
