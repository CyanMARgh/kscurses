anchor_lt :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{corner = zs0.corner, size = zs0.size};
}
anchor_rt :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{
		top = zs0.top,
		left = zs0.left + ss.x - ss0.x,
		size = zs0.size
	};
}
anchor_t :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{
		top = zs0.top,
		left = zs0.left,
		width = zs0.width + ss.x - ss0.x,
		height = zs0.height
	};
}


Links :: struct {
	left, right, top, bottom := -1, -1, -1, -1;
}
UI_Elem :: struct {
	zone_default : Ibox2;
	zone_current : Ibox2;

	type : enum u8 {
		EMPTY :: 0;
		TEXT_BLOCK :: 1;
		SELECT_LIST :: 2;
		BUTTON :: 3;
	} = .EMPTY;
	scale_mode := anchor_lt;
	links : Links;
}
UI_Text_Block :: struct {
	#as using base : UI_Elem = .{type = .TEXT_BLOCK};
	lines : [..]string;
}
UI_Button :: struct {
	#as using base : UI_Elem = .{type = .BUTTON};
	text : string;
	on_click : ()->() = ks_bell;

	// type : enum {
	// 	ON_OFF,
	// 	CLICK
	// } = .ON_OFF;
	// pressed := false;
}
UI_Select_List :: struct {
	#as using base : UI_Elem = .{type = .SELECT_LIST};
	options : []string;
	selected := -1;
	cursor := -1;
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


b_draw_line :: (builder : *String_Builder, beg : ivec2, line : string, lmax : int, mode : Graphics_Mode) {
	ltemp := line;
	if ltemp.count > lmax {
		ltemp.count = lmax;
	} // TODO fix for utf characters
	b_print(builder, beg, mode, "%", ltemp);
}
b_draw_text_block :: (builder : *String_Builder, using ui_text_block : *UI_Text_Block, style : *UI_Style) {
	rows := min(cast(int)(zone_current.height - 2), lines.count);
	for i : 1..rows {
		b_draw_line(builder, zone_current.corner + ivec2.{1, xx i}, lines[i - 1], zone_current.width - 2, style.text.default);
	}
}
b_draw_button :: (builder : *String_Builder, using ui_button : *UI_Button, style : *UI_Style) {
	row := (zone_current.height - 1) / 2;
	if !row return;
	//								TODO use length of string 
	free_space := zone_current.width - 2 - text.count;

	mode := style.text.default;
	if free_space < 0 {
		text_temp := text;
		text_temp.count += free_space;
		text_temp.data -= free_space / 2;

		b_print(builder, zone_current.corner + ivec2.{1, row}, mode, "%", text_temp);
	} else {
		b_print(builder, zone_current.corner + ivec2.{xx(1 + free_space / 2), row}, mode, "%", text);		
	}
}
b_draw_select_list :: (builder : *String_Builder, using ui_select_list : *UI_Select_List, style : *UI_Style) {
	rows := min(cast(int)(zone_current.height - 2), options.count);
	for i : 0..rows-1 {
		mode := ifx i == cursor
					ifx i == selected style.text.cursor_and_selection else style.text.cursor
				else
					ifx i == selected style.text.selection else style.text.default;					
		b_draw_line(builder, zone_current.corner + ivec2.{1, xx (i + 1)}, options[i], zone_current.width - 2, mode);
	}
}
b_draw_element :: (builder : *String_Builder, using ui_elem : *UI_Elem, style : *UI_Style) {
	if ui_elem.type == {
		case .EMPTY;
		case .TEXT_BLOCK;
		b_draw_text_block(builder, xx ui_elem, style);
		case .BUTTON;
		b_draw_button(builder, xx ui_elem, style);
		case .SELECT_LIST;
		b_draw_select_list(builder, xx ui_elem, style);
	}
}


handle_key :: (using ui_master : *UI_Master, _key : u64) {
	key := cast(Keys)_key;
	try_move :: (using ui_master : *UI_Master, id : int) {
		assert(id >= -1 && id < elems.count);
		if id == -1 {
			ks_bell();
		} else {
			active_elem = id;
		}
	}
	handle_key_inner :: (using ui_elem : *UI_Elem, key : Keys, is_inside_bef : bool) -> is_inside:bool {
		is_inside := is_inside_bef;
		if ui_elem.type == {
			case .BUTTON;
			if key == .ENTER then (cast(*UI_Button) ui_elem).on_click();
			case .SELECT_LIST;
			select_list := cast(*UI_Select_List)ui_elem;
			if !is_inside_bef {
				//is_nside_bef only if key == ENTER
				is_inside = true;
				select_list.cursor = 0;
			} else if key == {
				case .ESCAPE;
				select_list.cursor = -1;
				is_inside = false;
				case .UP;
				if(select_list.cursor > 0) select_list.cursor -= 1;
				case .DOWN;
				if(select_list.cursor < select_list.options.count - 1) select_list.cursor += 1;
				case .ENTER;
				select_list.selected = ifx select_list.selected == select_list.cursor then -1 else select_list.cursor;
			}
			case;
		}
		return is_inside;
	}

	if inside_elem {
		inside_elem = handle_key_inner(elems[active_elem], key, inside_elem);
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
		case .ENTER;
		inside_elem = handle_key_inner(elems[active_elem], key, inside_elem);
		case;
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
		// ks_print(.{2, 4}, .{}, "minimal size: % x %", size_min.x, size_min.y);
	}
	ks_write(builder_to_string(*builder, temp));
	reset_temporary_storage();
}
io_cycle :: (using ui_master : *UI_Master) {
	while !should_exit {
		input := ks_getch();
		r := handle_key(ui_master, input);
		ks_refresh(ui_master);
	}
}