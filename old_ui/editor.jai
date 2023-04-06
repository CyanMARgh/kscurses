UI_Editor :: struct {
	#as using base : UI_Elem = .{type = .EDITOR};

	MAX_CHARS :: 1000;
	MAX_LINES :: 100;

	buf_chars : [MAX_CHARS]Char_Type;
	buf_lengths : [MAX_LINES]int;

	cursor_i := 0;
	count := 0;
	is_active := false;
}
b_draw_editor :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_editor := cast(*UI_Editor) elem;

	assert(false);
}

handle_key_editor :: (elem : *UI_Elem, key : Key, is_inside : *bool) {
	using ui_editor := cast(*UI_Editor) elem;
	defer is_active = <<is_inside;

	if <<is_inside {
		if is_printable(key) {
			if !add_char(ui_editor, xx key) ui_bell();
		} else if key == {
			case .RIGHT; #through;
			case .LEFT;
			if !move_cursor(ui_editor, key) ui_bell();
			case .ESCAPE;
			if !break_line(ui_editor) ui_bell();
		}
	}
	// assert(false);
}
init :: (ui_editor : *UI_Editor) {
	// buf_lengths[0], buf_lengths[MAX_LINES - 1] = 0;
}
clear :: (ui_editor : *UI_Editor) {

}

//TODO  add "forced_rfresh" to UI_Elem
#scope_file
move_cursor :: (using ui_editor : *UI_Editor, dir : Key) -> bool {
	//==============
	if key == {
		case .LEFT;
		if cursor_i == 0 return false;

		case .RIGHT;
	}
	assert(false);
}
add_char :: (using ui_editor : *UI_Editor, char : Char_Type) -> bool {
	assert(false);
}
break_line :: (using ui_editor : *UI_Editor) -> bool {
	// assert(false);
}
