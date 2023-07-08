link_lr :: (el : *UI_Elem, er : *UI_Elem) {
	el.right = er;
	er.left = el; 
}
link_tb :: (et : *UI_Elem, eb : *UI_Elem) {
	et.bottom = eb;
	eb.top = et;
}
link_oi :: (eo : *UI_Elem, ei : *UI_Elem) {
	eo.inner = ei;
	ei.outer = eo;
}

link_grid :: (size : ivec2, elements : ..*UI_Elem) {
	assert(size.x * size.y == elements.count);
	for y : 0..size.y-1 {
		for x : 0..size.x-2 {
			i := x + size.x * y;
			link_lr(elements[i], elements[i + 1]);
		}
	}
	for y : 0..size.y-2 {
		for x : 0..size.x-1 {
			i := x + size.x * y;
			link_tb(elements[i], elements[i + size.x]);
		}
	}
}
link_grid :: (size : ivec2, elements : []UI_Elem) {
	assert(size.x * size.y == elements.count);
	for y : 0..size.y-1 {
		for x : 0..size.x-2 {
			i := x + size.x * y;
			link_lr(*elements[i], *elements[i + 1]);
		}
	}
	for y : 0..size.y-2 {
		for x : 0..size.x-1 {
			i := x + size.x * y;
			link_tb(*elements[i], *elements[i + size.x]);
		}
	}
}
link_row :: (elements : ..*UI_Elem) {
	for i : 0..elements.count-2 {
		link_lr(elements[i], elements[i + 1]);
	}
}
link_column :: (elements : ..*UI_Elem) {
	for i : 0..elements.count-2 {
		link_tb(elements[i], elements[i + 1]);
	}	
}
link_to_outer :: (eo : *UI_Elem, ei : ..*UI_Elem) {
	if ei.count > 0 {
		for ei {
			it.outer = eo;
		}
		eo.inner = ei[0];
	}

}
link_to_bottom :: (eb : *UI_Elem, et : ..*UI_Elem) {
	if et.count > 0 {
		for et {
			it.bottom = eb;
		}
		eb.top = et[0];
	}
}
link_to_top :: (et : *UI_Elem, eb : ..*UI_Elem) {
	if eb.count > 0 {
		for eb {
			it.top = et;
		}
		et.bottom = eb[0];
	}
}
link_to_right :: (er : *UI_Elem, el : ..*UI_Elem) {
	if el.count > 0 {
		for el {
			it.right = er;
		}
		er.left = el[0];
	}
}
link_to_left :: (el : *UI_Elem, er : ..*UI_Elem) {
	if er.count > 0 {
		for er {
			it.left = el;
		}
		el.right = er[0];
	}
}