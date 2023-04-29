// set_elements_scalable :: (group : *UI_Group, elements : ..UI_Group.Element_Scalable)

// anchor_lt :: (zone0 : Ibox2, size0 : ivec2, size : ivec2) -> Ibox2 {
// 	return zone0;
// }
// anchor_c :: (zone0 : Ibox2, size0 : ivec2, size : ivec2) -> Ibox2 {
// 	return .{size = zone0.size + size - size0, corner = zone0.corner};
// }
// anchor_rb :: (zone0 : Ibox2, size0 : ivec2, size : ivec2) -> Ibox2 {
// 	return .{size = zone0.size, corner = zone0.corner + size - size0};
// }


// Scalable_Group :: struct {
// 	#as using base_parent : UI_Parent = .{type = .SCALABLE_GROUP};

// 	Element :: struct {
// 		ptr : *UI_Elem;
// 		zone0 : Ibox2;
// 		scale_proc := anchor_lt;
// 	}
// 	elements : []Element;
// }

// //

// c_draw_scalable_group :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
// 	using cast(*UI_Group) ui_elem;
// 	for e : elements {
// 		e_zone := e.zone;
// 		if !inside(e_zone, zone.size) return false;
// 		e_zone.corner += zone.corner;
// 		if !c_draw(canvas, e.ptr, e_zone, style) return false;
// 	}
// 	return true;
// }