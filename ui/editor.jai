Edit_State :: enum u8 {
				//   ui state      history node
	NONE;		//		+
	ERASE;		//		+				+
	INPUT;		//		+				+
	INSERT;		//						+
	LINE_BREAK;	//						+
	LINE_CONCAT;//						+
};
Text_Buf :: struct {
	//TODO maybe change to [][..]Char_Type
	lines : [][]Char_Type;
	nl_on_end : bool;
}
Edit_Action :: struct {
	type := Edit_State.NONE;
	pos : ivec2;
	using difference : Text_Buf;
	pos_aft : ivec2;
}
History :: struct {
	MAX_SAVED :: 100;
	actions : [MAX_SAVED]Edit_Action;
	begin, saved := 0;
	// current_id, saved_bwd, saved_fwd := 0;
}
clear :: (action_data : *Edit_Action) {
	for l : action_data.lines array_free(l);
	array_free(action_data.lines);
	action_data.lines = .[];
	action_data.type = .NONE;
}
clear :: (using history : *History) {
	for i : 0..saved-1 {
		j := (i + begin) % MAX_SAVED;
		clear(actions.data + j);
	}
}
push_node :: (using history : *History, action : Edit_Action) {
	if saved == MAX_SAVED {
		clear(actions.data + begin);
		actions[begin] = action;
		begin = (begin + 1) % MAX_SAVED;
	} else {
		j := (begin + saved) % MAX_SAVED;
		actions[j] = action;
		saved += 1;
	}
}
pop_node :: (using history : *History) -> Edit_Action, bool {
	if saved > 0 {
		saved -= 1;
		j := (begin + saved) % MAX_SAVED;
		assert(actions[j].type != .NONE);
		return actions[j], true;
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

b_draw_editor :: (builder : *String_Builder, elem : *UI_Elem, style : *UI_Style) {
	using multiline_input := cast(*UI_Editor) elem;
	if action_data.type == {
		case .NONE;
		for line, i : main_buf {
			b_draw_line(builder, zone_current, i, line, style.text.default, 0);
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
				cut_right.count, cut_right.data = (line.count - l), (line.data + l);

				// ks_bell();

				b_draw_line(builder, zone_current, i, cut_left, style.text.default, 0);
				b_draw_line(builder, zone_current, i, buf, style.text.selection, l); //TODO change to default
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

				// ks_bell();

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

	if <<is_inside {
		if is_printable(key) {
			add_char(ui_editor, key);
		} else if key == {
			case .UP;
			apply_changes(ui_editor);
			if cursor.y > 0 {
				cursor.y -= 1;
				cursor.x = min(cursor.x, xx main_buf[cursor.y].count);
			} else if cursor.x > 0 {
				cursor.x = 0;
			} else {
				ui_bell();
			}
			case .DOWN;
			apply_changes(ui_editor);
			if cursor.y < main_buf.count - 1 {
				cursor.y += 1;
				cursor.x = min(cursor.x, xx main_buf[cursor.y].count);
			} else if cursor.x < main_buf[cursor.y].count - 1 {
				cursor.x = xx main_buf[cursor.y].count;
			} else {
				ui_bell();
			}
			case .LEFT;
			apply_changes(ui_editor);
			if cursor.x > 0 {
				cursor.x -= 1;
			} else if cursor.y > 0 {
				cursor.y -= 1;
				cursor.x = xx main_buf[cursor.y].count;
			} else {
				ui_bell();
			}
			case .RIGHT;
			apply_changes(ui_editor);
			if cursor.x < main_buf[cursor.y].count {
				cursor.x += 1;
			} else if cursor.y < main_buf.count - 1 {
				cursor.y += 1;
				cursor.x = 0;
			} else {
				ui_bell();
			}

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
is_space :: (code : Char_Type) -> bool {
	return code == xx #char " ";
}
add_char :: (using ui_editor : *UI_Editor, code : Key) {
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
	apply_changes(ui_editor);
	action_data.type = .LINE_BREAK; // prepare(ui_editor, .LINE_BREAK);
	apply_changes(ui_editor);
}

erase_left :: (using ui_editor : *UI_Editor) {
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

undo :: (using ui_editor : *UI_Editor) {
	apply_changes(ui_editor);

	ok : bool;
	action_data, ok = pop_node(*history);
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
		case;
		assert(false, tprint("type = %", action_data.type));
	}

	cursor = action_data.pos;
	clear(*action_data);
	action_data = Edit_Action.{};

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
		assert(!action_data.nl_on_end);

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
		assert(!action_data.nl_on_end);

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
		case; 
		assert(false);
	}
	add_to_history();

	add_to_history :: () #expand {
		action_data.pos_aft = cursor;
		push_node(*history, action_data);
		action_data = .{};
	}
	apply_erase :: () #expand {
		assert(action_data.type == .ERASE);
		assert(action_data.lines.count == 1);
		assert(!action_data.nl_on_end);

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
		assert(!action_data.nl_on_end);

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
			lines = NewArray(1, []Char_Type),
			nl_on_end = false
		};
	}
}
