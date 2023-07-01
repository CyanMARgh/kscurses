UI_Scalable_Group :: struct {
	#as using base_parent : UI_Parent = .{type = .SCALABLE_GROUP};

	Scale_Params :: struct {
		// using metrics : struct {
		x1, y1, x2, y2 : s32;
		#place x1; v1 : ivec2;
		#place x2; v2 : ivec2; 
		// };
		scale_mode : enum u8 {
			ANCHOR_TL ::  0; // v1 - size, v2 - offset from corner (both positive)
			ANCHOR_TR ::  1;
			ANCHOR_BL ::  2;
			ANCHOR_BR ::  3;

			STRETCH_T ::  4; // x1/2 - left/right offset, y1 - top offset, y2 - height
			STRETCH_B ::  5; // x1/2 - left/right offset, y1 - bottom offset, y2 - height
			STRETCH_L ::  6; // y1/2 - top/bottom offset, x1 - left offset, x2 - width
			STRETCH_R ::  7; // y1/2 - top/bottom offset, x1 - right offset, x2 - width

			STRETCH_C ::  8; // v1 - top-left offset, v2 - bottom-right offset
			CENTERIZE ::  9; // v1 - size, v2 - offset from center(signed)

			FIT_EXACT :: 10; //TODO
			FIT_ROUGH :: 11;
		} = .ANCHOR_TL;
	}

	Element :: struct {
		ptr : *UI_Elem;
		scale_params : Scale_Params;
	}

	elements : []Element;
}

get_zone :: (using zone : Ibox2, using scale_params : UI_Scalable_Group.Scale_Params) -> Ibox2 {
	if scale_mode == {
		case .ANCHOR_TL; return .{corner = corner + v2, size = v1};
		case .ANCHOR_TR; return .{corner = .{left + width - x2 - x1, top + y2}, size = v1};
		case .ANCHOR_BL; return .{corner = .{left + x2, top + height - y2 - y1}, size = v1};
		case .ANCHOR_BR; return .{corner = .{left + width - x2 - x1, top + height - y2 - y1}, size = v1};

		case .STRETCH_T; return .{corner = .{left + x1, top + y1}, size = .{width - x1 - x2, y2}};
		case .STRETCH_B; return .{corner = .{left + x1, top + height - y1 - y2}, size = .{width - x1 - x2, y2}};
		case .STRETCH_L; return .{corner = .{left + x1, top + y1}, size = .{x2, height - y1 - y2}};
		case .STRETCH_R; return .{corner = .{left + width - x1 - x2, top + y1}, size = .{x2, height - y1 - y2}};

		case .STRETCH_C; return .{corner = corner + v1, size = size - v1 - v2};
		case .CENTERIZE; return .{corner = corner + (size - v1) / 2 + v2 , size = v1};
	}
	assert(false);
	return .{};
}

set_sub_elements :: (group : *UI_Scalable_Group, elements : ..UI_Scalable_Group.Element) {
	group.elements = elements;
	for e : elements {
		e.ptr.parent = group;
	}
}
c_draw_scalable_group :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Scalable_Group) ui_elem;
	for e : elements {
		e_zone := get_zone(zone, e.scale_params);
		if !inside(e_zone, zone) return false;
		if !c_draw(canvas, e.ptr, e_zone, style) return false;
	}
	return true;
}
handle_key_scalable_group :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Scalable_Group) ui_elem;
	assert(cursor_state == .ON || cursor_state == .OUTSIDE);

	handled := false;
	if cursor_state == .OUTSIDE {
		assert(xx active_element);
		{
			ok := false;
			for e : elements if e.ptr == active_element ok = true;
			assert(ok);
		}
		handled = handle_key(active_element, key);
	} else {
		assert(xx !active_element);
	}
	return handled;
}