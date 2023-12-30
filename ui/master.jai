UI_Master :: struct {
	style : UI_Style;
	canvas : Canvas;
	root : *UI_Elem;
	should_exit := false;

	blink_stage := 0;

	before_draw : struct {
		proc := (data : *void) { };
		data : *void;
	};
	extra_handle : struct {
		proc := (e : Event, data : *void) { };
		data : *void;		
	};
}
__ui_master : UI_Master;


set_main_scene :: (scene : UI_Scene) {
	__ui_master.root = scene.root;
	set_active_recursive(scene.entry);
}
run_singlethread_ui :: () {
	use_default_winch_handler();
	using __ui_master;
	while 1 {
		before_draw.proc(before_draw.data);
		if should_exit break;
		draw(*__ui_master);
		reset_temporary_storage();
		handle_key(*__ui_master, ks_getch(block = false));
		if should_exit break;
	}
	deinit(*__ui_master);
}
run_multithread_ui :: () {
	use_events(tick_duration_ms = 530);
	__event_handler = .{
		proc = (e : Event, __data : *void) {
			using __ui_master;
			if e.type == {
				case .KEY;
				handle_key(*__ui_master, e.key);
				case .TICK;
				#if ENABLE_UI_BLINKING __ui_master.blink_stage = xx !__ui_master.blink_stage;
			}
			extra_handle.proc(e, extra_handle.data);
		},
		data = null
	}; defer __event_handler = .{};

	using __ui_master;

	while 1 {
		before_draw.proc(before_draw.data);
		if should_exit break;
		processed := wait_and_process_events();
		if should_exit break;
		if processed {
			draw(*__ui_master);
			reset_temporary_storage();			
		}
	}
	deinit(*__ui_master);
}

#scope_file
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

	ks_write(builder_to_string(*builder,, allocator = temp));
}
handle_key :: (using ui_master : *UI_Master, key : Key) {
	handled := handle_key(root, key);
	if handled return;

	if key == {
		case .ESCAPE; {
			should_exit = true;
			unset_active_recursive(__last_set);
		}
		case; if key != .READ_ERROR ui_bell();
	}
}
deinit :: (using ui_master : *UI_Master) {
	deinit(*canvas);
	__ui_master = .{};
}