UI_Text_Buf :: struct {
	#as using base : UI_Elem = .{type = .TEXT_BUF};
	lines : []string;
	lines_dynamic : *[]string;
}
c_draw_textbuf :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using cast(*UI_Text_Buf) ui_elem;

	lines_to_draw := ifx lines_dynamic then <<lines_dynamic else lines;
	for l, y : lines_to_draw {
		if y >= zone.height break;
		c_draw_line_ascii(canvas, l, zone, .{0, xx y}, style.text.default);
	}
	return true;
}
