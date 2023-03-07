Box_Style :: struct {
	lt, rt, lb, rb, l, r, t, b, c : Char;
}

style_double_line :: Box_Style.{
	lt = #run make_char(utf8("╔")),
	rt = #run make_char(utf8("╗")),
	lb = #run make_char(utf8("╚")),
	rb = #run make_char(utf8("╝")),
	l  = #run make_char(utf8("║")),
	r  = #run make_char(utf8("║")),
	t  = #run make_char(utf8("═")),
	b  = #run make_char(utf8("═")),
	c  = #run make_char(utf8(" "))
};
style_single_line :: Box_Style.{
	lt = #run make_char(utf8("┌")),
	rt = #run make_char(utf8("┐")),
	lb = #run make_char(utf8("└")),
	rb = #run make_char(utf8("┘")),
	l  = #run make_char(utf8("│")),
	r  = #run make_char(utf8("│")),
	t  = #run make_char(utf8("─")),
	b  = #run make_char(utf8("─")),
	c  = #run make_char(utf8(" "))
};
style_default :: style_double_line;

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

UI_Elem :: struct {
	zone : Ibox2;
	type : enum {
		EMPTY;
	} = .EMPTY;
	scale_mode := anchor_lt;
	links : Links;
}

b_draw :: (builder : *String_Builder, using ui_elem : UI_Elem, ss0 : ivec2, ss : ivec2, style := style_default) -> bool {
	zs := scale_mode(zone, ss0, ss);
	if !inside(zs, ss) || zs.size.x < 2 || zs.size.y < 2 return false;
	b_box(builder, zs, style);
	return true;
}

Links :: struct {
	left, right, top, bottom := -1, -1, -1, -1;
}
UI_Master :: struct {
	size_min := ivec2.{-1, -1};
	size_default := ivec2.{-1, -1};
	elems : [..]*UI_Elem;
	active_elem := 0;
	inside_elem := false;
	should_exit := false;
}
add_elem :: (using ui_master : *UI_Master, elem : *UI_Elem) {
	array_add(*elems, elem);
}
clear :: (using ui_master : *UI_Master) {
	array_free(elems);
}
// Keys :: enum u64 {
// 	UP		:: 0x415B1B;
// 	DOWN	:: 0x425B1B;
// 	RIGHT	:: 0x435B1B;
// 	LEFT	:: 0x445B1B;
// 	ENTER	:: 0x0D;
// 	ESCAPE	:: 0x1B;
// }
add_link_lr :: (using ui_master : *UI_Master, i : int, j : int) {
	elems[i].links.right = j;
	elems[j].links.left = i;
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
	if key == {
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
	}
}
// TODO -> resize & draw
ks_draw :: (using master : *UI_Master) -> bool {
	ss := terminal_state.size;
	defer reset_temporary_storage();
	end :: () #expand {
		ks_print(.{2, 1}, .{}, "screen is too small!");
		ks_print(.{2, 2}, .{}, "current size: % x %", ss.x, ss.y);
		ks_print(.{2, 3}, .{}, "minimal size: % x %", size_min.x, size_min.y);
		ks_print(.{2, 4}, .{}, "recomended size: % x %", size_default.x, size_default.y);
		`return false;
	}
	ks_clear_screen();
	builder := String_Builder.{allocator = temp};
	if !inside(size_min, ss) then end();

	for e, i : elems {
		style := ifx i == active_elem then style_double_line else style_single_line;
		if !b_draw(*builder, e, size_default, ss, style) then end();
	}
	ks_write(builder_to_string(*builder, temp));
	return true;
}
io_cycle :: (using ui_master : *UI_Master) {
	while !should_exit {
		input := ks_getch();
		r := handle_key(ui_master, input);
		ks_draw(ui_master);
	}
}

b_box :: (builder : *String_Builder, zone : Ibox2, using style := style_default, clear_center := false) {
	assert(inside(zone, terminal_state.size));
	b_move_cursor(builder, zone.corner);
	b_putchar(builder, lt);
	for x : 1..zone.size.x-2 b_putchar(builder, t);
	b_putchar(builder, rt);

	for y : 1..zone.size.y-2 {
		b_move_cursor(builder, .{zone.corner.x, zone.corner.y + y});
		b_putchar(builder, l);
		if clear_center {
			for x : 1..zone.size.x-2 b_putchar(builder, c);
		} else {
			b_move_cursor(builder, .{zone.corner.x + zone.size.x - 1, zone.corner.y + y});
		}
		b_putchar(builder, r);
	}

	b_move_cursor(builder, .{zone.corner.x, zone.corner.y + zone.size.y - 1});
	b_putchar(builder, lb);
	for x : 1..zone.size.x-2 b_putchar(builder, b);
	b_putchar(builder, rb);
}
t_box :: (zone : Ibox2, style := style_default, clear_center := false) -> string {
	builder := String_Builder.{allocator=temp};
	b_box(*builder, zone, style, clear_center);
	return builder_to_string(*builder, temp); 
}
ks_box :: (zone : Ibox2, style := style_default, clear_center := false) {
	ks_write(t_box(zone, style, clear_center));
}

ss_min := ivec2.{40, 10};
ss0 := ivec2.{50, 30};
left_box := UI_Elem.{
	zone = .{
		corner = .{0, 0},
		size = .{20, 10}
	}
};
middle_box := UI_Elem.{
	zone = .{
		corner = .{20, 0},
		size = .{10, 10}
	},
	scale_mode = anchor_t
};
right_box := UI_Elem.{
	zone = .{
		corner = .{30, 0},
		size = .{20, 10}
	},
	scale_mode = anchor_rt
};


ui_master := UI_Master.{
	size_min = .{40, 10},
	size_default = .{50, 30}
};

demo_3 :: () {
	add_elem(*ui_master, *left_box);
	add_elem(*ui_master, *middle_box);
	add_elem(*ui_master, *right_box);

	add_link_lr(*ui_master, 0, 1);
	add_link_lr(*ui_master, 1, 2);

	refresh_all :: () {
		ks_draw(*ui_master);
	};
	terminal_state.on_resize = refresh_all;

	use_ks_curses();
	io_cycle(*ui_master);
}

#scope_file
