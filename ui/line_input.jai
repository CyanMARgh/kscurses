Char_Type :: u8;
UI_Line_Input :: struct {
	#as using base : UI_Elem = .{type = .LINE_INPUT};
	buffer : []Char_Type;

	// resizeable := false;
	ptr_left, ptr_right : int;
	offset : int;
}

handle_key_line_input :: (ui_elem : *UI_Elem, key : Key) -> bool {
	using ui_line_input := cast(*UI_Line_Input) ui_elem;

	handle_inner :: (using ui_line_input : *UI_Line_Input, key : Key) -> bool {
		if is_printable(key) {
			return add_char(ui_line_input, xx key);
		} else if key == {
			case .LEFT; #through;
			case .RIGHT;
			return move_ptr(ui_line_input, key);
			case .BACKSPACE;
			return remove_char_left(ui_line_input);
			case .ESCAPE;
			cursor_state = .ON;
			return true;
		}
		return false;		
	}

	if cursor_state == .IN {
		return handle_inner(ui_line_input, key);
	} else if cursor_state == .ON && key == .ENTER {
		cursor_state = .IN;
		return true;
	}

	return false;
}
c_draw_line_input :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Line_Input) ui_elem;

	fix_offset :: () #expand {
		if ptr_left - offset < 0 {
			offset = ptr_left;
		} else if ptr_left - offset >= zone.width {
			offset = ptr_left - zone.width + 1;
		}
	}
	fix_offset();

	left_part, right_part : string;
	left_part.data, left_part.count = buffer.data, ptr_left;

	right_part.data, right_part.count = buffer.data + ptr_right + 1, (buffer.count - ptr_right - 1);

	c_draw_line_ascii(canvas, left_part, zone, .{xx -offset, 0}, style.text.default);
	c_draw_line_ascii(canvas, right_part, zone, .{xx (ptr_left - offset), 0}, style.text.default);

	terminal_state.cursor = ifx cursor_state == .IN then zone.corner + ivec2.{xx(ptr_left - offset), 0} else .{-1, -1};

	return true;
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

is_printable :: (key : Key) -> bool {
	code := cast(u64) key;
	return (code >= #char" " && code <= #char"~");
}

get_string :: (using ui_line_input : *UI_Line_Input) -> string {
	result : string;
	size := ptr_left + (buffer.count - ptr_right - 1);
	result.count = size;
	result.data = alloc(size);

	memcpy(result.data, buffer.data, ptr_left);
	memcpy(result.data + ptr_left, buffer.data + ptr_right + 1, buffer.count - ptr_right - 1);
	return result;
}
reset :: (using ui_line_input : *UI_Line_Input) {
	ptr_left = 0;
	ptr_right = buffer.count - 1;
}