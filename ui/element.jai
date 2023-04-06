// UI_Drawable :: struct

UI_Elem :: struct {
	type : enum u8 {
		NONE :: 0;
		BUTTON :: 1;
		TEXT_BUF :: 2;
		GROUP :: 3;
		SELECT_LIST :: 4;
		SCENE_MANAGER :: 5;
	} = .NONE;
	MAX_TYPES :: 10;

	// visual data, TODO
	// =======
	using visual_data : struct {
		cursor_state : enum u8 { OUTSIDE :: 0; ON :: 1; IN :: 2; } = .OUTSIDE;
		box_type : enum u8 { NONE :: 0; BORDER :: 1; NO_BORDER :: 2; } = .BORDER;		
	}

	links : struct {
		left, right, bottom, top, inner, outer : *UI_Elem;
		parent : *UI_Parent;
	}
}
c_draw :: (canvas : *Canvas, using ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	// tmp_copy := <<ui_elem; defer assert(<<ui_elem == tmp_copy);
	// TODO add assertion

	ok := box_type == .NONE || c_box(canvas, zone, ifx cursor_state == .ON then style.box.cursor else style.box.default, box_type == .BORDER);

	if !ok return false;
	content_zone := ifx box_type == .BORDER then cut_border(zone, 1) else zone;
	if ui_elem.type == {
		case .NONE;
		return true;
		case .TEXT_BUF;
		return c_draw_textbuf(canvas, ui_elem, content_zone, style);
		case .GROUP;
		return c_draw_group(canvas, ui_elem, content_zone, style);
		case .BUTTON;
		return c_draw_button(canvas, ui_elem, content_zone, style);
		case .SELECT_LIST;
		return c_draw_select_list(canvas, ui_elem, content_zone, style);
		case .SCENE_MANAGER;
		return c_draw_scene_manager(canvas, ui_elem, content_zone, style);
		case;
		assert(false);
	}
	return false;
}
c_draw_line_ascii :: (canvas : *Canvas, _line : string, zone : Ibox2, _offset : ivec2, mode : Graphics_Mode) {
	offset := _offset;
	view := _line;

	if offset.y < 0 || offset.y >= zone.height return;
	if offset.x < 0 {
		view.count += offset.x;
		view.data -= offset.x;
		offset.x = 0;
	}
	if offset.x + view.count > zone.width {
		view.count = zone.width - offset.x;
	}
	for x : 0..view.count-1 {
		c_putchar(canvas, .{code = xx view[x], mode = mode}, zone.corner + offset + ivec2.{xx x, 0});
	}
}

handle_key_move :: (using ui_elem : *UI_Elem, key : Key) -> handled:bool {
	active_elem := ui_elem;
	assert(active_elem.cursor_state == .ON);
	try_move :: (new_elem : *UI_Elem) #expand {
		if new_elem {
			unset_active_recursive(`active_elem);
			set_active_recursive(new_elem);
			`active_elem = new_elem;
		}
	}
	if key == {
		case .LEFT; 	try_move(links.left);
		case .RIGHT;	try_move(links.right);
		case .UP; 		try_move(links.top);
		case .DOWN; 	try_move(links.bottom);
		case .ESCAPE;	try_move(links.outer);
		case .ENTER;	try_move(links.inner);;
	}
	assert(active_elem.cursor_state == .ON);
	return ui_elem != active_elem;
}

handle_key :: (using ui_elem : *UI_Elem, key : Key) -> handled:bool {
	handled : bool;
	
	if type == {
		case .NONE; #through;
		case .TEXT_BUF;
		handled = handle_key_move(ui_elem, key);
		case .GROUP;
		handled = handle_key_group(ui_elem, key);
		case .BUTTON;
		handled = handle_key_button(ui_elem, key);
		case .SELECT_LIST;
		handled = handle_key_select_list(ui_elem, key);
		case .SCENE_MANAGER;
		handled = handle_key_scene_manager(ui_elem, key);
		case;
		assert(false);
	}
	return handled;
}
