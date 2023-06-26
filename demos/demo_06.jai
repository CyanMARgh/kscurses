demo_06 :: () {
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

	line_input.extra_handler.data = *(struct{_line_input : type_of(*line_input); _lines : type_of(*lines); _text_buf : type_of(*text_buf);}).{*line_input, *lines, *text_buf};
	line_input.extra_handler.proc = (key : Key, __data : *void) -> bool {
		using cast(*struct{_line_input : type_of(*line_input); _lines : type_of(*lines); _text_buf : type_of(*text_buf);}) __data;
		if key == .ENTER {
			str := get_string(_line_input);
			reset(_line_input);
			array_add(_lines, str);
			_text_buf.lines = <<_lines;
			return true;
		}
		return false;		
	};

	text_buf.extra_handler.data = *(struct{_lines : type_of(*lines); _text_buf : type_of(*text_buf);}).{*lines, *text_buf};
	text_buf.extra_handler.proc = (key : Key, __data : *void) -> bool {
		using cast(*struct{_lines : type_of(*lines); _text_buf : type_of(*text_buf);}) __data;
		if key == .ENTER && _lines.count > 0 {
			str := pop(_lines);
			free(str);
			_text_buf.lines = <<_lines;
			return true;
		}
		return false;		
	};

	use_ks_curses();
	run_singlethread_ui();
	// run_multithread_ui();
}