UI_Master :: struct {
	style : UI_Style;
	canvas : Canvas;
	root : *UI_Elem;
	should_exit := false;

	// before_draw := (){};
	before_draw : struct {
		proc := (data : *void){};
		data : *void;
	};
}

draw :: (using ui_master : *UI_Master) {
	new_zone := Ibox2.{size = terminal_state.size};
	builder : String_Builder;

	if new_zone != canvas.zone {
		resize_clear(*canvas, new_zone);
	}
	ok := c_draw(*canvas, root, canvas.zone, *style);
	if ok {
		ks_draw_canvas(*canvas);
	} else {
		b_mode_set(*builder, style.text.default);
		b_clear_screen(*builder);
		b_print(*builder, .{0, 0}, style.text.debug, "screen to small: %x%", terminal_state.size.x, terminal_state.size.y);
	}
	b_cursor_set_visibility(*builder, terminal_state.cursor != ivec2.{-1, -1});
	if terminal_state.cursor != ivec2.{-1, -1} then b_move_cursor(*builder, terminal_state.cursor);

	ks_write(builder_to_string(*builder, allocator = temp));
	reset_temporary_storage();
}

handle_key :: (using ui_master : *UI_Master, key : Key) {
	handled := handle_key(root, key);
	if handled return;

	if key == {
		case .ESCAPE; should_exit = true;
		case; if key != .READ_ERROR ui_bell();
	}
}

io_cycle :: (using ui_master : *UI_Master) {
	while !should_exit {
		before_draw.proc(before_draw.data);
		draw(ui_master);
		key := ks_getch(block = false);
		handle_key(ui_master, key);
	}
	deinit(ui_master);
}

deinit :: (using ui_master : *UI_Master) {
	deinit(*canvas);
}

set_scene :: (ui_master : *UI_Master, scene : UI_Scene) {
	ui_master.root = scene.root;
	set_active_recursive(scene.entry);
}
