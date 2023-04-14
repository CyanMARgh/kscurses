UI_Text_Buf :: struct {
	#as using base : UI_Elem = .{type = .TEXT_BUF};
	lines : []string;
}
c_draw_textbuf :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Text_Buf) ui_elem;
	for l, y : lines {
		c_draw_line_ascii(canvas, l, zone, .{0, xx y}, style.text.default);
	}
	return true;
}
