UI_Select_List :: struct {
	#as using base : UI_Elem = .{type = .SELECT_LIST};
	only_one := true;
	options : []string;
	selected : []bool;

	selected_id := -1;
	cursor, offset := 0, 0;

	prefix_default  := "[ ]";
	prefix_selected := "[+]";
}
handle_key_select_list :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Select_List) ui_elem;
	assert(cursor_state != .OUTSIDE);
	if cursor_state == .ON {
		if key == .ENTER {
			cursor_state = .IN;
			return true;
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
			if only_one {
				if cursor == selected_id {
					selected_id = -1;
				} else {
					selected_id = cursor;
				}
			} else {
				selected[cursor] ^= true;
			}
			case;
			return false;
		}
		return true;
	}
	return false;
}
init :: (select_list : *UI_Select_List, only_one := true) {
	select_list.only_one = only_one;
	if !only_one select_list.selected = NewArray(select_list.options.count, bool);
}
deinit :: (using select_list : *UI_Select_List) {
	array_free(selected);
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
		is_selected := ifx only_one then i == selected_id else selected[i];
		prefix := ifx is_selected then prefix_selected else prefix_default;
		mode := ifx i == cursor && cursor_state == .IN
					ifx is_selected style.text.cursor_and_selection else style.text.cursor
				else
					ifx is_selected style.text.selection else style.text.default;

		c_draw_line_ascii(canvas, prefix, zone, .{0, xx y}, mode);
		c_draw_line_ascii(canvas, options[i], zone, .{xx prefix.count, xx y}, mode);
	}
	return true;
}