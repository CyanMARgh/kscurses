UI_Button :: struct {
	#as using base : UI_Elem = .{type = .BUTTON};
	text : string;
	on_click : ()->() = ui_bell;

	// type : enum {
	// 	ON_OFF,
	// 	CLICK
	// } = .ON_OFF;
	// pressed := false;
}
b_draw_button :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_button : *UI_Button = xx elem;
	row := (zone_current.height - 1) / 2;
	if !row return;
	//								TODO use length of string 
	free_space := zone_current.width - 2 - text.count;

	mode := style.text.default;
	if free_space < 0 {
		text_temp := text;
		text_temp.count += free_space;
		text_temp.data -= free_space / 2;

		b_print(builder, zone_current.corner + ivec2.{1, row}, mode, "%", text_temp);
	} else {
		b_print(builder, zone_current.corner + ivec2.{xx(1 + free_space / 2), row}, mode, "%", text);		
	}
}
handle_key_button :: (elem : *UI_Elem, key : Key, inside_bef : *bool) {
	if key == .ENTER then (cast(*UI_Button)elem).on_click();
}