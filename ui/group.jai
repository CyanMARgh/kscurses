// TODO
//			           zone_0        canvas_size
// Scale_Mode :: #type(Ibox2, ivec2, ivec2) -> (Ibox2);
//							  canvas_size_0     zone

UI_Group :: struct {
	#as using base_parent : UI_Parent = .{type = .GROUP};

	Element :: struct {
		ptr : *UI_Elem;
		zone : Ibox2;
	}

	elements : []Element;
}
set_sub_elements :: (group : *UI_Group, elements : ..UI_Group.Element) {
	group.elements = elements;
	for e : elements {
		e.ptr.parent = group;
	}
}
c_draw_group :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Group) ui_elem;
	for e : elements {
		e_zone := e.zone;
		if !inside(e_zone, zone.size) return false;
		e_zone.corner += zone.corner;
		if !c_draw(canvas, e.ptr, e_zone, style) return false;
	}
	return true;
}
handle_key_group :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Group) ui_elem;
	handled : bool;
	if cursor_state == .ON {
		assert(!active_element);
		handled = handle_key_move(ui_elem, key);		
	} else if cursor_state == .OUTSIDE {
		assert(xx active_element);
		{
			ok := false;
			for e : elements if e.ptr == active_element ok = true;
			assert(ok);
		}
		handled = handle_key(active_element, key);
	} else {
		assert(false);
	}
	return handled;
}