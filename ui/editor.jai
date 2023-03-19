Edit_State :: enum u8 {
				//   ui state      history node
	NONE;		//		+
	ERASE;		//		+				+
	INPUT;		//		+				+
	INSERT;		//						+
	LINE_BREAK;	//						+
	LINE_CONCAT;//						+
	SELECTION;	//		+
	ERASE_SEL;	//						+
};
Text_Buf :: struct {
	//TODO maybe change to [][..]Char_Type
	lines : [][]Char_Type;
}
Edit_Action :: struct {
	type := Edit_State.NONE;
	pos : ivec2;
	using difference : Text_Buf;
	pos_aft : ivec2;
}
clear :: (action_data : *Edit_Action) {
	for l : action_data.lines array_free(l);
	array_free(action_data.lines);
	action_data.lines = .[];
	action_data.type = .NONE;
}
History :: struct {
	MAX_SAVED :: 100;
	actions : [MAX_SAVED]Edit_Action;
	begin, saved_prev, saved_total := 0;
	// current_id, saved_bwd, saved_fwd := 0;
}
clear :: (using history : *History) {
	for i : 0..saved_total-1 {
		j := (i + begin) % MAX_SAVED;
		clear(actions.data + j);
	}
}
add_node :: (using history : *History, action : Edit_Action) {
	assert(action.type != .NONE && action.type != .SELECTION);

	if saved_total > saved_prev new_timeline();
	if saved_total == MAX_SAVED {
		clear(actions.data + begin);
		actions[begin] = action;
	} else {
		j := (begin + saved_prev) % MAX_SAVED;
		saved_prev += 1;
		saved_total += 1;
		actions[j] = action;
	}

	new_timeline :: () #expand {
		for i : saved_prev..saved_total-1 {
			j := (begin + i) % MAX_SAVED;
			clear(actions.data + j);
		}
		saved_total = saved_prev;
	}
}
get_node_for_undo :: (using history : *History) -> Edit_Action, bool {
	if saved_prev > 0 {
		saved_prev -= 1;
		j := (begin + saved_prev) % MAX_SAVED;
		return actions[j], true;
	} else {
		return .{}, false;
	}
}
get_node_for_redo :: (using history : *History) -> Edit_Action, bool {
	if saved_prev < saved_total {
		j := (begin + saved_prev) % MAX_SAVED;
		action := actions[j];
		saved_prev += 1;
		return action, true;
	} else {
		return .{}, false;
	}
}


clipboard_multiline : Text_Buf;

UI_Editor :: struct {
	#as using base : UI_Elem = .{type = .EDITOR};

	main_buf : [..][]Char_Type;
	action_data : Edit_Action;

	cursor : ivec2;
	on_enter_press : (ui_line_input : *UI_Line_Input)->() = null;
	has_selection := false;

	history : History;

	// selection_edge : int;
	// max_length := 100;
	// max_heigth := 100;
	// view_offset : int;
}

selection_edges :: (using ui_editor : *UI_Editor) -> el:ivec2, er:ivec2 {
	assert(action_data.type == .SELECTION || action_data.type == .ERASE_SEL);
	e1, e2 := action_data.pos, cursor;
	if e1.y < e2.y || (e1.y == e2.y && e1.x < e2.x) {
		return e1, e2;
	} else {
		return e2, e1;
	}
}

get_string :: (using ui_editor : *UI_Editor) -> string {
	apply_changes(ui_editor);
	length, offset := 0;
	for line : main_buf {
		for c : line {
			length += length_code(xx c);
		}
		length += 1;
	}
	str_data := cast(*u8)alloc(length);

	for line : main_buf {
		for c : line {
			cl := length_code(xx c);
			memcpy(xx (str_data + offset), *c, cl);
			offset += cl;
		}
		str_data[offset] = xx #char "\n";
		offset += 1;
	}
	result : string;
	result.data, result.count = str_data, length;
	return result;	
}

b_draw_editor :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using ui_editor := cast(*UI_Editor) elem;
	if action_data.type == {
		case .NONE;
		for line, i : main_buf {
			b_draw_line(builder, zone_current, i, line, style.text.default, 0);
		}
		case .SELECTION;
		el, er := selection_edges(ui_editor);
		if el.y == er.y {
			for line, i : main_buf {
				if i == el.y {
					cut_left, cut_center, cut_right : []Char_Type;

					cut_left.count, cut_left.data = el.x, line.data;
					cut_center.count, cut_center.data = er.x - el.x, line.data + el.x;
					cut_right.count, cut_right.data = line.count - er.x, line.data + er.x;

					b_draw_line(builder, zone_current, i, cut_left, style.text.default, 0);
					b_draw_line(builder, zone_current, i, cut_center, style.text.selection, el.x);
					b_draw_line(builder, zone_current, i, cut_right, style.text.default, er.x);
				} else {
					b_draw_line(builder, zone_current, i, line, style.text.default, 0);
				}
			}
		} else {
			for line, i : main_buf {
				cut_left, cut_right : []Char_Type;

				if i < el.y || i > er.y {
					b_draw_line(builder, zone_current, i, line, style.text.default, 0);
				} else if i == el.y {
					cut_left.count, cut_left.data = el.x, line.data;
					cut_right.count, cut_right.data = line.count - el.x, line.data + el.x;

					b_draw_line(builder, zone_current, i, cut_left, style.text.default, 0);
					b_draw_line(builder, zone_current, i, cut_right, style.text.selection, el.x);					
				} else if i < er.y {
					b_draw_line(builder, zone_current, i, line, style.text.selection, 0);
				} else if i == er.y {
					cut_left.count, cut_left.data = er.x, line.data;
					cut_right.count, cut_right.data = line.count - er.x, line.data + er.x;

					b_draw_line(builder, zone_current, i, cut_left, style.text.selection, 0);
					b_draw_line(builder, zone_current, i, cut_right, style.text.default, er.x);
				} else {
					assert(false);
				}
			}
		} 

		case .INPUT;
		assert(action_data.lines.count == 1);

		ii := action_data.pos.y;
		buf := action_data.lines[0];
		l, w := action_data.pos.x, buf.count;

		for line, i : main_buf {
			if i == ii {
				cut_left, cut_right : []Char_Type;
				cut_left.count, cut_left.data = l, line.data;
				cut_right.count, cut_right.data = line.count - l, line.data + l;

				// ks_bell();

				b_draw_line(builder, zone_current, i, cut_left, style.text.default, 0);
				b_draw_line(builder, zone_current, i, buf, style.text.default, l);
				b_draw_line(builder, zone_current, i, cut_right, style.text.default, l + w);
			} else {
				b_draw_line(builder, zone_current, i, line, style.text.default, 0);
			}
		}

		case .ERASE;
		assert(action_data.lines.count == 1);
		buf := action_data.lines[0];

		ii := action_data.pos.y;
		r, w := action_data.pos.x, buf.count;

		for line, i : main_buf {
			if i == ii {
				cut_left, cut_right : []Char_Type;
				cut_left.count, cut_left.data = r - w, line.data;
				cut_right.count, cut_right.data = (line.count - r), (line.data + r);

				b_draw_line(builder, zone_current, i, cut_left, style.text.default, 0);
				b_draw_line(builder, zone_current, i, cut_right, style.text.default, r - w);
			} else {
				b_draw_line(builder, zone_current, i, line, style.text.default, 0);
			}
		}

		case;
		assert(false);
	}
}

handle_key_editor :: (elem : *UI_Elem, key : Key, is_inside : *bool) {
	using ui_editor := cast(*UI_Editor)elem;

	//TODO -> to functions
	move_pref :: () #expand {
		if action_data.type == .SELECTION {
			action_data.type = .NONE;
		} else {
			apply_changes(ui_editor);
		}
	}
	shift_move_pref :: () #expand {
		if action_data.type != .SELECTION {
			apply_changes(ui_editor);
			action_data.type = .SELECTION;
			action_data.pos = cursor;
		}
	}


	if <<is_inside {
		if is_printable(key) {
			add_char(ui_editor, key);
		} else if key == {
			case .UP;	
			move_pref();
			move_up();
			case .DOWN;
			move_pref();
			move_down();
			case .LEFT;
			move_pref();
			move_left();
			case .RIGHT;
			move_pref();
			move_right();

			case .SHIFT_LEFT;
			shift_move_pref();
			move_left();
			case .SHIFT_RIGHT;
			shift_move_pref();
			move_right();
			case .SHIFT_UP;
			shift_move_pref();
			move_up();
			case .SHIFT_DOWN;
			shift_move_pref();
			move_down();


			case .ESCAPE;
			apply_changes(ui_editor);
			<<is_inside = false;
			case .ENTER;
			break_line(ui_editor);
			case .BACKSPACE;
			erase_left(ui_editor);
			case .CTRL_Z;
			undo(ui_editor);
			case;
			ui_bell();
		}
	} else if key == .ENTER {
		<<is_inside = true;
	}

	if <<is_inside {
		terminal_state.cursor = zone_current.corner + ivec2.{1, 1} + cursor;
	} else {
		terminal_state.cursor = .{-1, -1};
	}

	// TODO -> bool
	move_left :: () #expand {
		if cursor.x > 0 {
			cursor.x -= 1;
		} else if cursor.y > 0 {
			cursor.y -= 1;
			cursor.x = xx main_buf[cursor.y].count;
		} else {
			ui_bell();
		}
	}
	move_right :: () #expand {
		if cursor.x < main_buf[cursor.y].count {
			cursor.x += 1;
		} else if cursor.y < main_buf.count - 1 {
			cursor.y += 1;
			cursor.x = 0;
		} else {
			ui_bell();
		}
	}
	move_up :: () #expand {
		if cursor.y > 0 {
			cursor.y -= 1;
			cursor.x = min(cursor.x, xx main_buf[cursor.y].count);
		} else if cursor.x > 0 {
			cursor.x = 0;
		} else {
			ui_bell();
		}
	}
	move_down :: () #expand {
		if cursor.y < main_buf.count - 1 {
			cursor.y += 1;
			cursor.x = min(cursor.x, xx main_buf[cursor.y].count);
		} else if cursor.x < main_buf[cursor.y].count - 1 {
			cursor.x = xx main_buf[cursor.y].count;
		} else {
			ui_bell();
		}
	}
}
init :: (using ui_editor : *UI_Editor) {
	array_add(*main_buf, .[]);
}
clear :: (using ui_editor : *UI_Editor) {
	apply_changes(ui_editor);
	for l : main_buf {
		array_free(l);
	}
	array_free(main_buf);
	clear(*history);
}

#scope_file
is_space :: (code : u64) -> bool {
	return code == #char " ";
}
add_char :: (using ui_editor : *UI_Editor, code : Key) {
	if action_data.type == .SELECTION {
		action_data.type = .ERASE_SEL;
	}

	should_apply := false;
	if action_data.type == .INPUT {
		c := action_data.lines[0].count;
		should_apply = c > 0 && !is_space(action_data.lines[0][c - 1]) && is_space(xx code);
	} else {
		should_apply = true;
	}

	if should_apply {
		apply_changes(ui_editor);
		prepare(ui_editor, .INPUT);
	}

	add_to_buf(ui_editor, code);
	cursor.x += 1;

	add_to_buf :: (using ui_editor : *UI_Editor, code : Key) {
		line_old_buf := action_data.lines[0]; defer array_free(line_old_buf);
		line_new_buf := NewArray(line_old_buf.count + 1, Char_Type);
		memcpy(xx line_new_buf.data, xx line_old_buf.data, line_old_buf.count * size_of(Char_Type));
		line_new_buf[line_old_buf.count] = xx code;
		action_data.lines[0] = line_new_buf;		
	}
}

break_line :: (using ui_editor : *UI_Editor) {
	if action_data.type == .SELECTION then action_data.type = .ERASE_SEL;
	apply_changes(ui_editor);
	action_data.type = .LINE_BREAK; // prepare(ui_editor, .LINE_BREAK);
	apply_changes(ui_editor);
}

erase_left :: (using ui_editor : *UI_Editor) {
	if action_data.type == .SELECTION {
		action_data.type = .ERASE_SEL;
		apply_changes(ui_editor);
		return;
	}

	should_apply := false;
	if action_data.type != .ERASE then should_apply = true;

	if cursor.x > 0 {
		if should_apply {
			apply_changes(ui_editor);
			prepare(ui_editor, .ERASE);
		}
		cursor.x -= 1;
		action_data.lines[0].data -= 1;
		action_data.lines[0].count += 1;
	} else if cursor.y > 0 {
		apply_changes(ui_editor);
		action_data.type = .LINE_CONCAT; // <- TODO move to prepare
		action_data.pos = cursor;
		apply_changes(ui_editor);
	} else {
		ui_bell();
	}
}

redo :: (using ui_editor : *UI_Editor) {
	apply_changes(ui_editor);

	ok : bool;
	action_data, ok = get_node_for_redo(*history);
	if !ok {
		ui_bell();
		return;
	}
}

undo :: (using ui_editor : *UI_Editor) {
	apply_changes(ui_editor);

	ok : bool;
	action_data, ok = get_node_for_undo(*history);
	if !ok {
		ui_bell();
		return;
	}

	if action_data.type == {
		case .INPUT;
		undo_input();
		case .LINE_BREAK;
		undo_line_break();
		case .ERASE;
		undo_erase();
		case .LINE_CONCAT;
		undo_line_concat();
		case .ERASE_SEL;
		undo_erase_sel();
		case;
		assert(false, tprint("type = %", action_data.type));
	}

	cursor = action_data.pos;
	// clear(*action_data);
	action_data = Edit_Action.{};

	undo_erase_sel :: () #expand {
		assert(action_data.type == .ERASE_SEL);
		assert(action_data.lines.count > 0);

		pos_aft := action_data.pos_aft;

		if action_data.lines.count == 1 {
			line_new := main_buf[pos_aft.y]; defer array_free(line_new);
			line_buf := action_data.lines[0];
			l := pos_aft.x;
			w := line_buf.count;
			line_old := NewArray(w + line_new.count, Char_Type);

			memcpy(xx line_old.data, xx line_new.data, l * size_of(Char_Type));
			memcpy(xx (line_old.data + l), xx line_buf.data, w * size_of(Char_Type));
			memcpy(xx (line_old.data + l + w), xx (line_new.data + l), (line_new.count - l) * size_of(Char_Type));
			main_buf[pos_aft.y] = line_old;
		} else if pos_aft.y == main_buf.count - 1 && main_buf[pos_aft.y].count == pos_aft.x {
			line_new := main_buf[pos_aft.y]; defer array_free(line_new);
			line_buf0 := action_data.lines[0];
			line_old0 := NewArray(line_new.count + line_buf0.count, Char_Type);
			memcpy(xx line_old0.data, xx line_new.data, line_new.count * size_of(Char_Type));
			memcpy(xx (line_old0.data + line_new.count), xx line_buf0.data, line_buf0.count * size_of(Char_Type));
			main_buf[pos_aft.y] = line_old0;

			for i : 1..action_data.lines.count-1 {
				line := action_data.lines[i];
				// action_data.lines[i] = .[];
				array_add(*main_buf, array_copy(line));
			}
		} else {
			line_new := main_buf[pos_aft.y]; defer array_free(line_new);
			line_buf_upper := action_data.lines[0];
			line_buf_lower := action_data.lines[action_data.lines.count - 1];

			line_old_upper := NewArray(pos_aft.x + line_buf_upper.count, Char_Type);
			memcpy(xx line_old_upper.data, xx line_new.data, pos_aft.x * size_of(Char_Type));
			memcpy(xx (line_old_upper.data + pos_aft.x), xx line_buf_upper.data, line_buf_upper.count * size_of(Char_Type));

			line_old_lower := NewArray((line_new.count - pos_aft.x) + line_buf_lower.count, Char_Type);
			memcpy(xx line_old_lower.data, xx line_new.data, (line_new.count - pos_aft.x) * size_of(Char_Type));
			memcpy(xx (line_old_lower.data + line_new.count - pos_aft.x), xx line_buf_lower.data, line_buf_lower.count * size_of(Char_Type));

			main_buf[pos_aft.y] = line_old_upper;
			array_insert_at(*main_buf, line_old_lower, pos_aft.y + 1);

			for i : 1..action_data.lines.count-2 {
				line := action_data.lines[i];
				array_insert_at(*main_buf, array_copy(line), pos_aft.y + i);
			}
		}
	}
	undo_line_break :: () #expand {
		assert(action_data.type == .LINE_BREAK);

		pos := action_data.pos;
		assert(main_buf.count > pos.y + 1);
		line_upper := main_buf[pos.y]; defer array_free(line_upper);
		assert(line_upper.count == pos.x, tprint("pos = %, count = %", pos.x, line_upper.count));
		line_lower := main_buf[pos.y + 1]; defer array_free(line_lower);
		line_old := NewArray(line_upper.count + line_lower.count, Char_Type);
		memcpy(xx (line_old.data), xx (line_upper.data), line_upper.count * size_of(Char_Type));
		memcpy(xx (line_old.data + line_upper.count), xx (line_lower.data), line_lower.count * size_of(Char_Type));

		main_buf[pos.y] = line_old;
		array_ordered_remove_by_index(*main_buf, pos.y + 1);
	}
	undo_line_concat :: () #expand {
		assert(action_data.type == .LINE_CONCAT);

		pos := action_data.pos;
		pos_aft := action_data.pos_aft;
		assert(pos.y > 0 && pos.y <= main_buf.count && pos_aft.y + 1 == pos.y, tprint("[%, %]", pos, pos_aft));

		line_new := main_buf[pos_aft.y]; defer array_free(line_new);
		assert(pos_aft.x <= line_new.count);
		array_insert_at(*main_buf, .[], pos_aft.y);
		// assert(false);

		line_upper := NewArray(pos_aft.x, Char_Type);
		line_lower := NewArray((line_new.count - pos_aft.x), Char_Type);
		memcpy(xx line_upper.data, xx line_new.data, pos_aft.x * size_of(Char_Type));
		memcpy(xx line_lower.data, xx (line_new.data + pos_aft.x), (line_new.count - pos_aft.x) * size_of(Char_Type));

		main_buf[pos_aft.y] = line_upper;
		main_buf[pos.y] = line_lower;

		cursor = .{0, pos_aft.y};
	}
	undo_input :: () #expand {
		assert(action_data.type == .INPUT);
		assert(action_data.lines.count == 1);

		line_buf := action_data.lines[0];
		l, w := action_data.pos.x, line_buf.count;
		line_new := main_buf[action_data.pos.y]; defer array_free(line_new);
		line_old := NewArray(line_new.count - w, Char_Type);

		memcpy(xx (line_old.data), xx (line_new.data), l * size_of(Char_Type));
		memcpy(xx (line_old.data + l), xx (line_new.data + l + w), (line_new.count - l - w) * size_of(Char_Type));

		main_buf[action_data.pos.y] = line_old;
	}
	undo_erase :: () #expand {
		assert(action_data.type == .ERASE);
		assert(action_data.lines.count == 1);

		line_new := main_buf[action_data.pos.y]; defer array_free(line_new);
		line_erased := action_data.lines[0];

		r := action_data.pos.x;
		w := line_erased.count;
		l := r - w;

		line_old := NewArray(line_new.count + w, Char_Type);

		memcpy(xx line_old.data, xx line_new.data, l * size_of(Char_Type));
		memcpy(xx (line_old.data + l), xx line_erased.data, w * size_of(Char_Type));
		memcpy(xx (line_old.data + r), xx (line_new.data + l), (line_new.count - l) * size_of(Char_Type));

		main_buf[action_data.pos.y] = line_old;
	}
}

apply_changes :: (using ui_editor : *UI_Editor) {
	if action_data.type == {
		case .NONE;
		return;
		case .INPUT;
		apply_input();
		case .ERASE;
		apply_erase();
		case .LINE_BREAK;
		apply_line_break();
		case .LINE_CONCAT;
		apply_line_concat();
		case .ERASE_SEL;
		apply_earse_sel();
		case .SELECTION;
		action_data.type = .NONE;
		return; // TODO ?
		case; 
		assert(false, tprint("type = %", action_data.type));
	}
	add_to_history();

	apply_earse_sel :: () #expand {
		assert(action_data.type == .ERASE_SEL);
		assert(action_data.lines.count == 0);

		el, er := selection_edges(ui_editor);
		assert(el.y >= 0 && el.y < main_buf.count && el.x >= 0 && el.x <= main_buf[el.y].count && er.x >= 0 && er.x <= main_buf[er.y].count,
			tprint("[%, %, %, %, %]", el, er, main_buf.count, main_buf[el.y].count, main_buf[er.y].count));
		line_collapsed := NewArray(el.x + main_buf[er.y].count - er.x, Char_Type);

		memcpy(xx line_collapsed.data, xx main_buf[el.y].data, el.x * size_of(Char_Type));
		memcpy(xx (line_collapsed.data + el.x), xx (main_buf[er.y].data + er.x), (main_buf[er.y].count - er.x) * size_of(Char_Type));

		action_data.lines = NewArray(er.y - el.y + 1, []Char_Type);

		if el.y == er.y {
			// TODO do nothing if el == er
			action_data.lines[0] = NewArray(er.x - el.x, Char_Type);
			memcpy(xx action_data.lines[0].data, xx (main_buf[el.y].data + el.x), (er.x - el.x) * size_of(Char_Type));
		} else {
			action_data.lines[0] = NewArray(main_buf[el.y].count - el.x, Char_Type);
			memcpy(xx action_data.lines[0].data, xx (main_buf[el.y].data + el.x), (main_buf[el.y].count - el.x) * size_of(Char_Type));
			for i : el.y+1..er.y-1 {
				action_data.lines[i - el.y] = main_buf[i];
			}
			action_data.lines[er.y - el.y] = NewArray(er.x, Char_Type);
			memcpy(xx action_data.lines[er.y - el.y].data, xx main_buf[er.y].data, er.x * size_of(Char_Type));
		}

		array_free(main_buf[el.y]);
		if el.y != er.y then array_free(main_buf[er.y]);
		main_buf[el.y] = line_collapsed;
		for i : el.y+1..er.y {
			array_ordered_remove_by_index(*main_buf, el.y + 1);
		}
		cursor = el;
	}
	add_to_history :: () #expand {
		action_data.pos_aft = cursor;
		add_node(*history, action_data);
		action_data = .{};
	}
	apply_erase :: () #expand {
		assert(action_data.type == .ERASE);
		assert(action_data.lines.count == 1);

		line_old := main_buf[action_data.pos.y]; defer array_free(line_old);
		r := action_data.pos.x;
		w := action_data.lines[0].count;
		l := r - w;
		line_new := NewArray(line_old.count - w, Char_Type);

		memcpy(xx line_new.data, xx line_old.data, l * size_of(Char_Type));
		memcpy(xx (line_new.data + l), xx (line_old.data + r), (line_old.count - r) * size_of(Char_Type));
		action_data.lines[0] = array_copy(action_data.lines[0]);

		main_buf[action_data.pos.y] = line_new;
	}
	apply_input :: () #expand {
		assert(action_data.type == .INPUT);
		assert(action_data.lines.count == 1);

		line_old := main_buf[action_data.pos.y]; defer array_free(line_old);
		line_buf := action_data.lines[0];
		l, w := action_data.pos.x, line_buf.count;
		line_new := NewArray(line_old.count + w, Char_Type);

		memcpy(xx line_new.data, xx line_old.data, l * size_of(Char_Type));
		memcpy(xx (line_new.data + l), xx line_buf.data, w * size_of(Char_Type));
		memcpy(xx (line_new.data + l + w), xx (line_old.data + l), (line_old.count - l) * size_of(Char_Type));

		main_buf[action_data.pos.y] = line_new;
	}
	apply_line_break :: () #expand {
		assert(action_data.type == .LINE_BREAK);
		action_data.pos = cursor;

		pos := action_data.pos;

		line_old := main_buf[pos.y]; defer array_free(line_old);
		array_insert_at(*main_buf, .[], pos.y);

		line_upper := NewArray(pos.x, Char_Type);
		line_lower := NewArray((line_old.count - pos.x), Char_Type);
		memcpy(xx line_upper.data, xx line_old.data, pos.x * size_of(Char_Type));
		memcpy(xx line_lower.data, xx (line_old.data + pos.x), (line_old.count - pos.x) * size_of(Char_Type));

		main_buf[pos.y] = line_upper;
		main_buf[pos.y + 1] = line_lower;

		cursor = .{0, pos.y + 1};
	}
	apply_line_concat :: () #expand {
		assert(action_data.type == .LINE_CONCAT);

		pos := action_data.pos;
		assert(main_buf.count > pos.y && pos.y > 0 && pos.x == 0);

		line_upper := main_buf[pos.y - 1]; defer array_free(line_upper);
		line_lower := main_buf[pos.y]; defer array_free(line_lower);

		line_new := NewArray(line_upper.count + line_lower.count, Char_Type);
		memcpy(xx (line_new.data), xx (line_upper.data), line_upper.count * size_of(Char_Type));
		memcpy(xx (line_new.data + line_upper.count), xx (line_lower.data), line_lower.count * size_of(Char_Type));

		main_buf[pos.y - 1] = line_new;
		array_ordered_remove_by_index(*main_buf, pos.y);

		cursor = .{xx line_upper.count, action_data.pos.y - 1};
	}
}
prepare :: (using ui_editor : *UI_Editor, should_be : Edit_State) {
	assert(action_data.type == .NONE);
	if should_be == {
		case .INPUT;
		prepare_input();
		case .ERASE;
		prepare_erase();
		case;
		assert(false);
	}
	action_data.type = should_be;

	prepare_erase :: () #expand {
		action_data.pos = cursor;
		action_data.lines = NewArray(1, []Char_Type);
		action_data.lines[0].data = main_buf[cursor.y].data + cursor.x;
		action_data.lines[0].count = 0;
	}
	prepare_input :: () #expand {
		assert(action_data.type == .NONE);
		action_data = Edit_Action.{
			pos = cursor,
			type = .INPUT,
			lines = NewArray(1, []Char_Type)
		};
	}
}
