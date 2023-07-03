UI_Progress_Bar :: struct {
	#as using base : UI_Elem = .{type = .PROGRESS_BAR};

	value     :  float;
	value_ptr : *float;

	draw_proc := (percent : float, pix_coord : float) -> Vector3 { return ifx pix_coord < percent then Vector3.{0, 1, 0} else .{0, 0, 0}; }
	show_percent := true;
}

set_value :: (progress_bar : *UI_Progress_Bar, value : float) {
	progress_bar.value = value;
	progress_bar.value_ptr = null;
}
set_value_ptr :: (progress_bar : *UI_Progress_Bar, value_ptr : *float) {
	progress_bar.value_ptr = value_ptr;
}

c_draw_progress_bar :: (canvas : *Canvas, ui_elem : *UI_Elem, _zone : Ibox2, style : *UI_Style) -> bool {
	using progress_bar := cast(*UI_Progress_Bar) ui_elem;
	value_current := ifx value_ptr then <<value_ptr else value;
	zone := _zone;
	if zone.width < 6 return false;
	if show_percent {
		percent_str := tprint("%1%%", formatFloat(value_current * 100, width = 4, trailing_width = 1, zero_removal = .NO));
		c_draw_line_ascii(canvas, percent_str, zone, .{zone.width - 5, zone.height / 2}, style.text.default);
		zone.width -= 5;
	}
	for x : 0..zone.width-1 {
		pix_coord := (x + .5) / zone.width;
		char := find_best_char(draw_proc(value_current,  pix_coord), true);
		for y : 0..zone.height-1 {
			c_putchar(canvas, char, zone.corner + ivec2.{x, y});
		}
	}
	return true;
}
