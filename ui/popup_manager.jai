MAX_POPUP_LEVES :: 10;

UI_Popup_Manager :: struct {
	#as using base_parent : UI_Parent = .{type = .POPUP_MANAGER, box_type = .NONE};

	layers : [MAX_POPUP_LEVES]UI_Popup;

	layers_count := 0;
}

set_background :: (using ui_popup_manager : *UI_Popup_Manager, scene : UI_Scene) {
	assert(layers_count == 0);
	layers[0] = .{root = scene.root, entry = scene.entry};
	scene.root.parent = xx ui_popup_manager;
	layers_count = 1;
}

handle_key_popup_manager :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using ui_popup_manager := cast(*UI_Popup_Manager) ui_elem;
	assert(layers_count > 0, "0 layers in popup manager");
	if !handle_key(active_element, key) {
		if key == .ESCAPE && layers_count > 1 {
			pop(ui_popup_manager);
			return true;
		} else {
			return false;
		}
	} else {
		return true;
	}
}

//TODO  __broken_element : *UI_Element;
c_draw_popup_manager :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using ui_popup_manager := cast(*UI_Popup_Manager) ui_elem;
	assert(layers_count > 0, "0 layers in popup manager");
	for i : 0..layers_count-1 {
		popup_zone := zone;
		ok : bool;
		if layers[i].size != .{-1, -1} then {
			popup_zone, ok = centered_box(zone, layers[i].size);
			if !ok return false;			
		}
		if !c_draw(canvas, layers[i].root, popup_zone, style) return false;
	}
	return true;
}

pop :: (using ui_popup_manager : *UI_Popup_Manager) {	
	assert(layers_count > 1, "can't pop background");
	layers_count -= 1;
	unset_active_recursive(__last_set);
	layers[layers_count].root.parent = null;
	set_active_recursive(layers[layers_count - 1].entry);

}
push :: (using ui_popup_manager : *UI_Popup_Manager, scene : UI_Popup) {
	assert(layers_count < MAX_POPUP_LEVES, "too much popup layers");
	unset_active_recursive(__last_set);

	layers[layers_count] = scene;
	scene.root.parent = xx ui_popup_manager;
	set_active_recursive(layers[layers_count].entry);

	layers_count += 1;
}