Char_Type :: u8;
UI_Line_Input :: struct {
	#as using base : UI_Elem = .{type = .LINE_INPUT};
	buffer : []Char_Type;

	// resizeable := false;
	// TODO add ability to resize
	ptr_left, ptr_right : int;
	view_offset : int;
}

handle_key_line_input :: (ui_elem : *UI_Elem, key : Key) -> bool {
	//===
}
c_draw_line_input :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	//===
}

init :: (using ui_line_input : *UI_Line_Input, max_length := 100) {
	buffer = NewArray(max_length, Char_Type);
	ptr_left, ptr_right = 0, max_length - 1;
}
add_char :: (using ui_line_input : *UI_Line_Input, c : Char_Type) -> bool {
	if ptr_left > ptr_right return false;
	buffer[ptr_left] = c;
	ptr_left += 1;
	return true;
}
remove_char_left :: (using ui_line_input : *UI_Line_Input) -> bool {
	if ptr_left == 0 return false;
	ptr_left -= 1;
	return true;
}
move_ptr :: (using ui_line_input : *UI_Line_Input, key : Key) -> bool {
	if key == {
		case .LEFT;
		if ptr_left > 0 {
			ptr_left -= 1;
			buffer[ptr_right] = buffer[ptr_left];
			ptr_right -= 1;
			return true;
		}
		case .RIGHT;
		if ptr_right < buffer.count-1 {
			ptr_right += 1;
			buffer[ptr_left] = buffer[ptr_right];
			ptr_left += 1;
			return true;
		}
		case;
		assert(false);
	}
	return false;
}
deinit :: (using ui_line_input : *UI_Line_Input) {
	array_free(buffer);
}