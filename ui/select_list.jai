UI_Select_List :: struct {
	#as using base : UI_Elem = .{type = .SELECT_LIST};
	// only_one := true;
	options : []string;
	selected := -1;
	cursor, offset := 0, 0;
}
handle_key_select_list :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Select_List) ui_elem;
	assert(cursor_state != .OUTSIDE);
	if cursor_state == .ON {
		if key == .ENTER {
			cursor_state = .IN;
			return true;
		} else {
			return handle_key_move(ui_elem, key);
		}
	} else {
		if key == {
			case .DOWN;
			if cursor < options.count - 1 then cursor += 1;
			case .UP;
			if cursor > 0 then cursor -= 1;
			case .ESCAPE;
			cursor_state = .ON;
			case .ENTER;
			if cursor == selected {
				selected = -1;
			} else {
				selected = cursor;
			}
			case;
			return false;
		}
		return true;
	}
}
c_draw_select_list :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Select_List) ui_elem;

	rows := min(cast(int) zone.height, options.count - offset);

	fix_offset :: () #expand {
		if cursor - offset < 0 {
			offset = cursor;
		} else if cursor - offset >= zone.height {
			offset = cursor - zone.height + 1;
		}
	}
	fix_offset();

	for y : 0..rows-1 {
		i := y + offset;
		mode := ifx i == cursor && cursor_state == .IN
					ifx i == selected style.text.cursor_and_selection else style.text.cursor
				else
					ifx i == selected style.text.selection else style.text.default;
		c_draw_line_ascii(canvas, options[i], zone, .{0, xx y}, mode);
	}
	return true;
}