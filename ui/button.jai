UI_Button :: struct {
	#as using base : UI_Elem = .{type = .BUTTON};
	text := "";
	on_click : struct {
		proc := (data : *void){};
		data : *void;
	};
}

handle_key_button :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Button) ui_elem;
	assert(cursor_state == .ON);
	assert(!links.inner);
	if key == .ENTER {
		on_click.proc(on_click.data);
		return true;
	} else {
		return handle_key_move(ui_elem, key);
	}
}
c_draw_button :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Button) ui_elem;
	mode := ifx cursor_state == .ON && box_type == .NONE then style.text.cursor else style.text.default;
	c_draw_line_ascii(canvas, text, zone, .{(zone.width - xx text.count) / 2, xx ((zone.height - 1) / 2)}, mode);
	return true;
}
