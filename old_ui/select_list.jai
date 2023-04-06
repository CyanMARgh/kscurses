UI_Select_List :: struct {
	#as using base : UI_Elem = .{type = .SELECT_LIST};
	options : []string; // -> [][]Char_Type
	selected := -1;
	cursor := -1;
}
b_draw_select_list :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_select_list : *UI_Select_List = xx elem;	
	rows := min(cast(int)(zone_current.height - 2), options.count);
	for i : 0..rows-1 {
		mode := ifx i == cursor
					ifx i == selected style.text.cursor_and_selection else style.text.cursor
				else
					ifx i == selected style.text.selection else style.text.default;
		b_draw_line(builder, zone_current, i, options[i], mode, 0);
	}
}
handle_key_select_list :: (elem : *UI_Elem, key : Key, is_inside : *bool) {
	select_list := cast(*UI_Select_List)elem;
	if !<<is_inside {
		<<is_inside = true;
		select_list.cursor = 0;
	} else if key == {
		case .ESCAPE;
		select_list.cursor = -1;
		<<is_inside = false;
		case .UP;
		if(select_list.cursor > 0) select_list.cursor -= 1;
		case .DOWN;
		if(select_list.cursor < select_list.options.count - 1) select_list.cursor += 1;
		case .ENTER;
		select_list.selected = ifx select_list.selected == select_list.cursor then -1 else select_list.cursor;
	}
}