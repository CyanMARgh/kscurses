demo_0 :: () {
	fill_function :: (coord : ivec2, size : ivec2) -> Char {
		bx, by := coord.x < 6 || coord.x >= size.x-6, coord.y < 3 || coord.y >= size.y-3;
		if bx && by {
			return make_char(#char "+",
				foreground = .BRIGHT_RED,
				background = .RED
			);
		} else if bx || by {
			return make_char(
				#char " ",
				background = ifx (coord.x / 2 + coord.y) % 2 Color.BLACK else .BRIGHT_BLACK
			);
		} else {
			return make_char(
				#char "|", 
				foreground = ifx coord.x * 2 < size.x Color.GREEN else .BRIGHT_GREEN,
				bold = (coord.x % (size.x / 2)) < size.x / 4,
				background = .BLACK,
				dim = coord.y * 2 < size.y,
				strikethrough = true
			);
		}
	}
	refresh_tab :: () {
		using app_state;
		for i : 0..ROWS-1 {
			background := ifx i == cursor Color.BRIGHT_YELLOW else .BRIGHT_WHITE;
			ks_print(
				.{9, xx (7 + i)},
				make_graphics_mode(foreground = .GREEN, background = background, bold = i == selection, dim = i == cursor),
				"option #%", i
			);
		}
		if selection != -1 {
			ks_print(
				.{9, 8 + ROWS},
				make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN),
				"selected option #%", selection
			);
		}
	}
	refresh_all :: () {
		using terminal_state;
		using app_state;
		ks_clear_screen();
		resize_no_fill(*main_window, .{size=size});
		fill(*main_window, fill_function);
		refresh(*main_window);
		ks_print(.{8, 4}, make_graphics_mode(background = .BLACK), "screen string size = %", print_string_size);
		ks_print(.{8, 5}, make_graphics_mode(background = .YELLOW), "window size = % %", size.x, size.y);
		refresh_tab();
	};
	terminal_state.on_resize = refresh_all;

	use_ks_curses();
	defer clear(main_window);

	using app_state;
	while 1 {
		input := ks_getch();
		if input == xx Keys.UP {
			if cursor > 0 {
				cursor -= 1;
			}
		} else if input == xx Keys.DOWN {
			if cursor < ROWS - 1 {
				cursor += 1;
			}
		} else if input == xx Keys.ENTER {
			if cursor == selection {
				selection = -1;
			} else {
				selection = cursor;
			}
		} else if input == xx Keys.ESCAPE {
			break;
		} else {
			continue;
		}		
		refresh_tab();
	}
}

#scope_file

main_window : Window;
app_state : struct {
	cursor, selection := 0, -1;
	ROWS :: 5;
}