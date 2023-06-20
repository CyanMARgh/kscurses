UI_Table :: struct {
	#as using base : UI_Elem = .{type = .TABLE};

	// auto_scale := false;
	// metrics : []int;
	columns := 0;
	rows := 0;

	// description : []string;
	content : [..]string;

	cursor, offset := 0;
	show_cursor := false;
}

handle_key_table :: (ui_elem : *UI_Elem, key : Key) -> handled:bool {
	return false;
}

c_draw_table_content :: (canvas : *Canvas, using ui_table : *UI_Table, zone : Ibox2, style : *UI_Style, rows_visible : int) -> bool {
	for y : 0..zone.height-1 {
		is_selected := y == cursor && show_cursor;
		mode := ifx is_selected then style.text.selection else style.text.default;
		separator_char := Char.{code = style.box.default.tb, mode = mode};

		if zone.width < columns {
			for x : 0..zone.width {
				c_putchar(canvas, separator_char, zone.corner + ivec2.{xx x, xx y});				
			}
		} else {
			i := y + offset;
			for x : 0..columns-1 {
				l := (zone.width + 1) *       x / columns;
				r := (zone.width + 1) * (x + 1) / columns - 1;
				if y < rows_visible {
					field_content := content[i * columns + x];
					field_content.count = min(field_content.count, r - l);					
					c_draw_line_ascii(canvas, field_content, zone, .{xx l, xx y}, mode);
				}
				if x != columns-1 c_putchar(canvas, separator_char, zone.corner + ivec2.{xx r, xx y});
			}			
		}
	}
	return true;
}

c_draw_table :: (canvas : *Canvas, ui_elem : *UI_Elem, zone : Ibox2, style : *UI_Style) -> bool {
	using ui_table := cast(*UI_Table) ui_elem;
	assert(rows * columns == content.count);

	rows_visible := min(cast(int) zone.height, rows - offset);

	fix_offset :: () #expand {
		if cursor - offset < 0 {
			offset = cursor;
		} else if cursor - offset >= zone.height {
			offset = cursor - zone.height + 1;
		}
	}
	fix_offset();

	ok := c_draw_table_content(canvas, ui_table, zone, style, rows_visible);
	return ok;
}
init :: (table : *UI_Table, description : []string) {
	table.columns = description.count;
	table.description = description;
}
init :: (table : *UI_Table, columns : int) {
	table.columns = columns;
}

add_line :: (using table : *UI_Table, line : ..string) {
	assert(line.count == columns);
	array_add(*content, ..line);
	rows += 1;
}
deinit :: (using table : *UI_Table) {
	array_free(content);
}

// TODO
// variadic columns count, different content types
// empty separator
// automatic scale, as option
// description
// align content left/right/center