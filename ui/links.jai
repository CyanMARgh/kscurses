link_lr :: (el : *UI_Elem, er : *UI_Elem) {
	el.links.right = er;
	er.links.left = el; 
}
link_tb :: (et : *UI_Elem, eb : *UI_Elem) {
	et.links.bottom = eb;
	eb.links.top = et;
}
link_oi :: (eo : *UI_Elem, ei : *UI_Elem) {
	eo.links.inner = ei;
	ei.links.outer = eo;
}

link_grid :: (size : ivec2, elements : ..*UI_Elem) {
	//TODO
}
link_row :: (elements : ..*UI_Elem) {
	for i : 0..elements.count-2 {
		link_lr(elements[i], elements[i + 1]);
	}
}
link_column :: (elements : ..*UI_Elem) {
	for i : 0..elements.count-2 {
		link_td(elements[i], elements[i + 1]);
	}	
}
link_to_outer :: (outer : *UI_Elem, inners : ..*UI_Elem) {
	for < inners {
		link_oi(outer, it);
	}
}