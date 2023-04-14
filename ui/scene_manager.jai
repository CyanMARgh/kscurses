UI_Scene :: struct {
	root : *UI_Elem;
	entry : *UI_Elem;
}
UI_Popup :: struct {
	root : *UI_Elem;
	entry : *UI_Elem;
	size : ivec2 = .{-1, -1};
}

UI_Scene_Manager :: struct {
	#as using base_parent : UI_Parent = .{type = .SCENE_MANAGER, box_type = .NONE};
	scenes : []UI_Scene;
}

set_sub_elements :: (ui_scene_manager : *UI_Scene_Manager, scenes : ..UI_Scene) {
	ui_scene_manager.scenes = scenes;
	for ui_scene_manager.scenes it.root.parent = ui_scene_manager;
}

handle_key_scene_manager :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	using cast(*UI_Scene_Manager) ui_elem;
	handled : bool;
	if cursor_state == .ON {
		assert(!active_element);
		handled = handle_key_move(ui_elem, key);		
	} else if cursor_state == .OUTSIDE {
		assert(xx active_element);
		{
			ok := false;
			for s : scenes if s.root == active_element ok = true;
			assert(ok);
		}
		handled = handle_key(active_element, key);
	} else {
		assert(false);
	}
	return handled;
}

c_draw_scene_manager :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Scene_Manager) ui_elem;
	return c_draw(canvas, active_element, zone, style);
}

switch_scene :: (using ui_scene_manager : *UI_Scene_Manager, id : int) {
	unset_active_recursive(__last_set);
	set_active_recursive(scenes[id].entry);
}
