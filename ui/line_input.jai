UI_Line_Input :: struct {
	#as using base : UI_Elem = .{type = .LINE_INPUT};

	line : []Char_Type;
	cursor : int;

	on_enter_press : (ui_line_input : *UI_Line_Input)->() = null;

	has_selection := false;
	selection_edge : int;
	max_length := 100;
	view_offset : int;
}
b_draw_line_input :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_line_input : *UI_Line_Input = xx elem;
	b_move_cursor(builder, zone_current.corner + ivec2.{1, 1});
	// TODO add .. & window_offset
	// ====================================
	local_builder : String_Builder = .{allocator = temp};
	if has_selection {
		left, right := selection_edges(ui_line_input);
		str_left, str_center, str_right : []Char_Type;
		str_left.data, str_left.count = line.data, left;
		str_center.data, str_center.count = line.data + left, right - left;
		str_right.data, str_right.count = line.data + right, line.count - right;

		b_draw_line(builder, zone_current, 0, str_left, style.text.default, view_offset);
		b_draw_line(builder, zone_current, 0, str_center, style.text.selection, view_offset + left);
		b_draw_line(builder, zone_current, 0, str_right, style.text.default, view_offset + right);
	} else {
		b_draw_line(builder, zone_current, 0, line, style.text.default, view_offset);
	}
}

update_vindow_offset :: (using ui_line_input : *UI_Line_Input) {
	lmax := zone_current.width - 2;
	// assert(view_offset == 0);
	if cursor + view_offset >= lmax {		
		view_offset = lmax - cursor - 1;
		// ui_bell();
	} else if cursor + view_offset < 0 {
		view_offset = -cursor;
	}
}

handle_key_line_input :: (elem : *UI_Elem, key : Key, is_inside : *bool) {
	using ui_line_input := cast(*UI_Line_Input)elem;

	move :: (delta : s32, shift : bool) #expand {
		c2 := `cursor + delta;

		if !shift then `has_selection = false;
		if shift && !`has_selection {
			has_selection = true;
			selection_edge = `cursor;
		}

		if c2 >= 0 && c2 <= line.count {
			cursor = c2;
		} else {
			 ui_bell();
		}

	}

	if <<is_inside {
		if is_printable(key) {
			add_char(ui_line_input, key);
		} else if key == {
			case .ESCAPE;
			<<is_inside = false;

			case .LEFT;
			move(-1, false);
			case .RIGHT;
			move( 1, false);
			case .SHIFT_LEFT;
			move(-1, true);
			case .SHIFT_RIGHT;
			move( 1, true);

			case .BACKSPACE;
			erase_char(ui_line_input, true);
			case .DELETE;
			erase_char(ui_line_input, false);

			case .CTRL_C;
			save_to_clipboard(ui_line_input);
			case .CTRL_V;
			insert_from_clipboard(ui_line_input);
		}
	} else {
		if is_printable(key) {
			<<is_inside = true;
			add_char(ui_line_input, key);
		} else if key == {
			case .ENTER;
			<<is_inside = true;
		}
	}
	update_vindow_offset(ui_line_input);
	if <<is_inside {
		terminal_state.cursor = zone_current.corner + ivec2.{xx(1 + cursor + view_offset), 1};
	} else {
		terminal_state.cursor = .{-1, -1};
	}
}
clear :: (using ui_line_input : *UI_Line_Input) {
	array_free(line);
}

selection_edges :: (using ui_line_input : *UI_Line_Input) -> l:int, r:int {
	if cursor < selection_edge {
		return cursor, selection_edge;
	} else {
		return selection_edge, cursor;
	}
}
clear_selection :: (using ui_line_input : *UI_Line_Input) {
	left, right := selection_edges(ui_line_input);
	assert(left >= 0 && right <= line.count && left <= right);

	new_line := NewArray(line.count - (right - left), Char_Type);
	defer {
		array_free(line);
		line = new_line;
	};

	memcpy(xx new_line.data, xx line.data, left * size_of(Char_Type));
	memcpy(xx (new_line.data + left), xx (line.data + right), (line.count - right) * size_of(Char_Type));

	cursor = left;
	has_selection = false;
}

is_capable :: (using ui_line_input : *UI_Line_Input, extra : int) -> bool {
	S := line.count + extra;
	if has_selection {
		l, r := selection_edges(ui_line_input);
		S -= r - l;
	}
	return max_length >= S;
}

add_char :: (using ui_line_input : *UI_Line_Input, code : Key) {
	assert(cursor >= 0 && cursor <= line.count);

	if !is_capable(ui_line_input, 1) return;

	// if line.count == max_length && (!has_selection || cursor == selection_edge) return;

	if has_selection {
		clear_selection(ui_line_input);
	}

	new_line := NewArray(line.count + 1, Char_Type);
	defer {
		array_free(line);
		line = new_line;
	};

	memcpy(xx new_line.data, xx line.data, cursor * size_of(Char_Type));
	memcpy(xx (new_line.data + cursor + 1), xx (line.data + cursor), (line.count - cursor) * size_of(Char_Type));
	new_line[cursor] = xx code;

	cursor += 1;
}
insert_from_clipboard :: (using ui_line_input : *UI_Line_Input) {
	assert(cursor >= 0 && cursor <= line.count);
	if !is_capable(ui_line_input, terminal_state.clipboard.count) return;

	if has_selection clear_selection(ui_line_input);
	new_line := NewArray(line.count + terminal_state.clipboard.count, Char_Type);
	defer {
		array_free(line);
		line = new_line;
	};
	memcpy(xx new_line.data, xx line.data, cursor * size_of(Char_Type));
	memcpy(xx (new_line.data + cursor), xx (terminal_state.clipboard.data), terminal_state.clipboard.count * size_of(Char_Type));
	memcpy(xx (new_line.data + cursor + terminal_state.clipboard.count), xx (line.data + cursor), (line.count - cursor) * size_of(Char_Type));
	cursor += terminal_state.clipboard.count;	
}
save_to_clipboard :: (using ui_line_input : *UI_Line_Input) {
	if has_selection && cursor != selection_edge {
		left, right := selection_edges(ui_line_input);
		save_to_clipboard(array_slice(line, left, right));
	} else {
		save_to_clipboard(line);
	}
}
erase_char :: (using ui_line_input : *UI_Line_Input, l_r := true) {
	assert(cursor >= 0 && cursor <= line.count);
	if has_selection {
		clear_selection(ui_line_input);
		return;
	}
	if cursor == (ifx l_r then 0 else line.count) {
		ui_bell();
		return;
	} 

	if !l_r then cursor += 1;
	new_line := NewArray(line.count - 1, Char_Type);
	defer {
		array_free(line);
		line = new_line;
	};

	memcpy(xx new_line.data, xx line.data, (cursor - 1) * size_of(Char_Type));
	memcpy(xx (new_line.data + cursor - 1), xx (line.data + cursor), (line.count - cursor) * size_of(Char_Type));
	cursor -= 1;
}

save_to_clipboard :: (data : []Char_Type) {
	// assert(false);
	array_free(terminal_state.clipboard);
	terminal_state.clipboard = array_copy(data);
}
