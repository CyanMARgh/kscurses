UI_Elem :: struct {
	type : enum u8 {
		NONE 			:: 0;
		BUTTON 			:: 1;
		TEXT_BUF 		:: 2;
		GROUP 			:: 3;
		SELECT_LIST 	:: 4;
		SCENE_MANAGER 	:: 5;
		POPUP_MANAGER 	:: 6;
		LINE_INPUT 		:: 7;
		SCALABLE_GROUP	:: 8;
		TABLE			:: 9;
	} = .NONE;

	using visual_data : struct {
		cursor_state : enum u8 { OUTSIDE :: 0; ON :: 1; IN :: 2; } = .OUTSIDE;
		box_type : enum u8 { NONE :: 0; BORDER :: 1; NO_BORDER :: 2; } = .BORDER;		
	}

	using links : struct {
		left, right, bottom, top, inner, outer : *UI_Elem;
		parent : *UI_Parent;
	}

	extra_handler : struct {
		proc : (key : Key, data : *void) -> bool = null;
		data : *void;
	}
}


vtable_c_draw : []#type (*Canvas, *UI_Elem, Ibox2, *UI_Style) -> (bool) = .[
	c_draw_default,
	c_draw_button,
	c_draw_textbuf,
	c_draw_group,
	c_draw_select_list,
	c_draw_scene_manager,
	c_draw_popup_manager,
	c_draw_line_input,
	c_draw_scalable_group,
	c_draw_table
];
c_draw :: (canvas : *Canvas, using ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	ok := box_type == .NONE || c_box(canvas, zone, ifx cursor_state == .ON && __ui_master.blink_stage != 1 then style.box.cursor else style.box.default, box_type == .BORDER);

	if !ok return false;
	content_zone := ifx box_type == .BORDER then cut_border(zone, 1) else zone;

	c_draw_proc := vtable_c_draw[xx ui_elem.type];
	assert(xx c_draw_proc);
	return c_draw_proc(canvas, ui_elem, content_zone, style);
}
c_draw_default :: (canvas : *Canvas, using ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool { return true; };
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

vtable_handle_key : []#type (*UI_Elem, Key) -> (bool) = .[
	handle_key_none,
	handle_key_button,
	handle_key_none,
	handle_key_group,
	handle_key_select_list,
	handle_key_scene_manager,
	handle_key_popup_manager,
	handle_key_line_input,
	handle_key_scalable_group,
	handle_key_table
];
handle_key :: (using ui_elem : *UI_Elem, key : Key) -> handled:bool {
	handle_proc := vtable_handle_key[ui_elem.type];
	assert(xx handle_proc);

	handled := handle_proc(ui_elem, key);
	// assert(cursor_state == .ON || cursor_state == .IN);
	if !handled && cursor_state == .ON {
		handled = handle_key_move(ui_elem, key);
	}
	
	if !handled && extra_handler.proc {
		handled = extra_handler.proc(key, extra_handler.data);
	}
	return handled;
}
handle_key_none :: (using ui_elem : *UI_Elem, key : Key) -> handled:bool { return false; }
handle_key_move :: (using ui_elem : *UI_Elem, key : Key) -> handled:bool {
	__ui_master.blink_stage = 0;
	restart_clock_cycle();

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