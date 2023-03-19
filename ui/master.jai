UI_Elem :: struct {
	zone_default : Ibox2;
	zone_current : Ibox2;

	type := Types.EMPTY; 
	using Types :: enum u8 {
		EMPTY 			:: 0;
		TEXT_BLOCK 		:: 1;
		SELECT_LIST 	:: 2;
		BUTTON 			:: 3;
		LINE_INPUT 		:: 4;
		EDITOR 			:: 5;
		// MULTILINE_INPUT	:: 5;
	}
	MAX_TYPES :: 10;

	scale_mode := anchor_lt;
	links : struct {
		left, right, top, bottom := -1, -1, -1, -1;
	};
}
UI_Master :: struct {
	size_min := ivec2.{-1, -1};
	size_default := ivec2.{-1, -1};
	size_current := ivec2.{-1, -1};	

	style : UI_Style;
	elems : []*UI_Elem;

	active_elem := 0;
	inside_elem := false;
	should_exit := false;

	after_ui_upate := (){}
}

set_elements :: (ui_master : *UI_Master, elems : ..*UI_Elem) #expand {
	ui_master.elems = array_copy(elems);
	`defer {
		array_free(ui_master.elems);
		ui_master.elems = .[];
	}
}
add_link_lr :: (using ui_master : *UI_Master, i : int, j : int) {
	elems[i].links.right = j;
	elems[j].links.left = i;
}
add_link_tb :: (using ui_master : *UI_Master, i : int, j : int) {
	elems[i].links.bottom = j;
	elems[j].links.top = i;
}

b_draw_line :: (builder : *String_Builder, zone : Ibox2, line_id : int, _view : []$T, mode : Graphics_Mode, x_offset : int) {
	view := _view;
	lmax := zone.width - 2;
	hmax := zone.height - 3;
	if line_id < 0 || line_id > hmax return;
	// left cut
	if x_offset < 0 {
		view.count += x_offset;
		view.data -= x_offset;
		x_offset = 0;
	}
	// right cut
	if x_offset + view.count > lmax {
		view.count = lmax - x_offset;
	}

	view_str : string;
	view_str.count = view.count * size_of(T);
	view_str.data = xx view.data;

	if view.count > 0 {
		b_print(builder, zone.corner + ivec2.{xx(1 + x_offset), xx(1 + line_id)}, mode, "%", view_str);
	}
}
b_draw_line :: (builder : *String_Builder, zone : Ibox2, line_id : int, view : string, mode : Graphics_Mode, x_offset : int) {
	b_draw_line(builder, zone, line_id, cast([]u8) view, mode, x_offset);
}
b_draw_element :: (builder : *String_Builder, using ui_elem : *UI_Elem, style : *UI_Style) {
	painter := painters[cast(int) ui_elem.type];
	if painter {
		painter(builder, ui_elem, style);
	}
}

Key_Handler_Type:: #type (*UI_Elem, Key, *bool);
Painter_Type 	:: #type (builder : *String_Builder, using ui_elem : *UI_Elem, style : *UI_Style);

key_handlers: [UI_Elem.MAX_TYPES] Key_Handler_Type;
painters 	: [UI_Elem.MAX_TYPES] Painter_Type;

init_ui :: () {
	add_impl :: (id : int, key_handler : Key_Handler_Type, painter : Painter_Type) {
		key_handlers[id] = key_handler;
		painters[id] = painter;
	}

	add_impl(xx UI_Elem.BUTTON, handle_key_button, b_draw_button);
	add_impl(xx UI_Elem.SELECT_LIST, handle_key_select_list, b_draw_select_list);
	add_impl(xx UI_Elem.LINE_INPUT, handle_key_line_input, b_draw_line_input);
	add_impl(xx UI_Elem.EDITOR, handle_key_editor, b_draw_editor);
	add_impl(xx UI_Elem.TEXT_BLOCK, null, b_draw_text_block);
}

handle_key :: (using ui_master : *UI_Master, key : Key) {
	try_move :: (using ui_master : *UI_Master, id : int) {
		assert(id >= -1 && id < elems.count);
		if id == -1 {
			ui_bell();
		} else {
			active_elem = id;
		}
	}
	handle_key_inner :: (using ui_elem : *UI_Elem, key : Key, is_inside : *bool) {
		handler := key_handlers[cast(int) ui_elem.type];
		if handler then handler(ui_elem, key, is_inside);
	}

	if inside_elem {
		handle_key_inner(elems[active_elem], key, *inside_elem);
	} else if key == {
		case .UP;
		try_move(ui_master, elems[active_elem].links.top);
		case .RIGHT;
		try_move(ui_master, elems[active_elem].links.right);
		case .LEFT;
		try_move(ui_master, elems[active_elem].links.left);
		case .DOWN;
		try_move(ui_master, elems[active_elem].links.bottom);
		case .ESCAPE;
		should_exit = true;
		case;
		handle_key_inner(elems[active_elem], key, *inside_elem);
	}
}
update_sizes :: (using ui_master : *UI_Master, size_new : ivec2) -> bool {
	size_current = size_new;
	ok := inside(size_min, size_new);
	for e : elems {
		zc := e.scale_mode(e.zone_default, size_default, size_current);
		e.zone_current = zc;
		ok &= inside(ivec2.{2, 2}, zc.size);
		assert(!ok || inside(zc, size_current), tprint("[%], [%], [%]. [%]", zc, size_current, size_default, size_min));
	}
	return ok;
}

ks_refresh :: (using ui_master : *UI_Master) {
	builder := String_Builder.{allocator = temp};
	b_mode_set(*builder, style.main_mode);
	b_clear_screen(*builder);
	fit := update_sizes(ui_master, terminal_state.size);
	if fit {
		for e, i : elems {
			charset := ifx i == active_elem then style.box.selected else style.box.default;
			b_box(*builder, e.zone_current, charset = charset, mode = style.main_mode, clear_center = true);
			b_draw_element(*builder, e, *style);
		}
	} else {
		b_print(*builder, .{2, 1}, style.text.debug, "screen is too small!");
		b_print(*builder, .{2, 2}, style.text.debug, "current size: % x %", size_current.x, size_current.y);
		b_print(*builder, .{2, 3}, style.text.debug, "recomended size: % x %", size_default.x, size_default.y);		
	}
	b_cursor_set_visibility(*builder, terminal_state.cursor != ivec2.{-1, -1});
	if terminal_state.cursor != ivec2.{-1, -1} then b_move_cursor(*builder, terminal_state.cursor);

	ks_write(builder_to_string(*builder, temp));
	reset_temporary_storage();
}
io_cycle :: (using ui_master : *UI_Master) {
	while !should_exit {
		input := ks_getch();
		r := handle_key(ui_master, input);
		after_ui_upate();
		ks_refresh(ui_master);
	}
}