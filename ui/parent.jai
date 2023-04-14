UI_Parent :: struct {
	#as using base : UI_Elem;
	active_element : *UI_Elem;
}

__last_set : *UI_Elem; // TODO

set_active_recursive :: (ui_elem : *UI_Elem) {
	assert(!__last_set); __last_set = ui_elem;
	assert(ui_elem.cursor_state == .OUTSIDE); ui_elem.cursor_state = .ON;

	current := ui_elem;
	while 1 {
		parent := current.parent;
		if !parent break;
		assert(!parent.active_element);
		parent.active_element = current;
		current = xx parent;
	}
}
unset_active_recursive :: (ui_elem : *UI_Elem) {
	assert(__last_set == ui_elem); __last_set = null;
	assert(ui_elem.cursor_state == .ON); ui_elem.cursor_state = .OUTSIDE;

	current := ui_elem;
	while 1 {
		parent := current.parent;
		if !parent break;
		assert(parent.active_element == current);
		parent.active_element = null;
		current = xx parent;
	}
}