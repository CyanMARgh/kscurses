UI_Text_Block :: struct {
	#as using base : UI_Elem = .{type = .TEXT_BLOCK};
	lines : [..]string;
	//TODO add align mode
}
b_draw_text_block :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_text_block : *UI_Text_Block = xx elem;	
	rows := min(cast(int)(zone_current.height - 2), lines.count);
	for i : 0..rows-1 {
		b_draw_line(builder, zone_current, i, lines[i], style.text.default, 0);
	}
}