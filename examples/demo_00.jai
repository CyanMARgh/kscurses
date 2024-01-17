demo_00 :: () {
	fill_function :: (coord : ivec2, zone_size : ivec2) -> Char {
		bx, by := coord.x < 6 || coord.x >= zone_size.x-6, coord.y < 3 || coord.y >= zone_size.y-3;
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
				foreground = ifx coord.x * 2 < zone_size.x Color.GREEN else .BRIGHT_GREEN,
				bold = coord.y < zone_size.y / 2,
				dim = (coord.x * 4 < zone_size.x) || (coord.x * 2 >= zone_size.x && coord.x * 4 < zone_size.x * 3),
				background = .BLACK,
				strikethrough = true
			);
		}
	}
	draw_tab :: () {
		using app_state;
		for i : 0..ROWS-1 {
			background := ifx i == cursor Color.BRIGHT_YELLOW else .BRIGHT_WHITE;
			c_draw_line_ascii(*main_canvas, 
				tprint("option #%", i),
				.{9, xx (7 + i)},
				make_graphics_mode(foreground = .GREEN, background = background, bold = i == selection, dim = i == cursor)
			);

			// ks_print(
			// 	.{9, xx (7 + i)},
			// 	make_graphics_mode(foreground = .GREEN, background = background, bold = i == selection, dim = i == cursor),
			// 	"option #%", i
			// );
		}
		if selection != -1 {
			c_draw_line_ascii(*main_canvas, 
				tprint("selected option #%", selection),
				.{9, xx (8 + ROWS)},
				make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN)
			);

			// ks_print(
			// 	.{9, 8 + ROWS},
			// 	make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN),
			// 	"selected option #%", selection
			// );
		}
		c_draw_line_ascii(*main_canvas,
			tprint("window size = % %", terminal_state.size.x, terminal_state.size.y),
			.{8, 5},
			make_graphics_mode(background = .YELLOW)	
		);
	}
	draw :: () {
		// using terminal_state;
		using app_state;
		// ks_mode_reset();
		// ks_clear_screen();

		// if main_canvas.zone.size != terminal_state.size {
			// log("size = %\n", terminal_state.size);
			resize(*main_canvas, terminal_state.size);
			// assert(false, "%\n", main_canvas);
			c_fill(*main_canvas, fill_function);
		// }
	
		draw_tab();
		ks_draw_canvas(*main_canvas);
		// log("printed = %\n", write_counter_delta());
	};

	use_ks_curses();
	use_default_winch_handler();
	defer deinit(*main_canvas);

	using app_state;
	while 1 {
		draw();
		input := ks_getch();
		if input == {
			case .UP;
			if cursor > 0 cursor -= 1;
			case .DOWN;
			if cursor < ROWS - 1 cursor += 1;
			case .ENTER;
			if cursor == selection {
				selection = -1;
			} else {
				selection = cursor;
			}
			case .ESCAPE;
			break;
		}
		reset_temporary_storage();
	}
}

#scope_file

main_canvas : Screen_Canvas;

app_state : struct {
	cursor, selection := 0, -1;
	ROWS :: 5;
}