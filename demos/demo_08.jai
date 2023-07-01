demo_08 :: () {
	init(); defer finalize();

	__event_handler.proc = (e : Event, __data : *void) {
		if #complete game_state == {
			case .START;
			if e.type == .KEY && e.key == .ENTER {
				game_state = .GAME;
				restart_clock_cycle();
			}
			case .GAME;
			if e.type == {
				case .KEY;
				new_dir := key_to_dir(e.key);
				if new_dir != .NONE && new_dir != backward(current_dir) {
					current_dir = new_dir;
					restart_clock_cycle();
					move();
				}
				case .TICK;
				move();
				case .WINCH;
				game_canvas.force_full_refresh = true;
			}
			case .END;
			if e.type == .KEY && e.key == .ENTER {
				restart();
				game_state = .GAME;
			}
		}
		if e.type == .KEY && e.key == .ESCAPE {
			stop_main = true;
		}
	};

	use_ks_curses();
	use_events(tick_duration_ms = 400);

	while !stop_main {
		if wait_and_process_events() {
			draw();
			reset_temporary_storage();
		}
	}
}

#scope_file
Direction :: enum u8 {
	UP		:: 0;
	RIGHT	:: 1;
	DOWN	:: 2;
	LEFT	:: 3;
	NONE	:: 4;
}
backward :: (dir : Direction) -> Direction {
	if #complete dir == {
		case .LEFT; return .RIGHT;
		case .RIGHT; return .LEFT;
		case .UP; return .DOWN;
		case .DOWN; return .UP;
		case .NONE; return .NONE;
	}
}
key_to_dir :: (key : Key) -> Direction {
	return	 ifx key == .UP		Direction.UP
		else ifx key == .RIGHT	Direction.RIGHT
		else ifx key == .DOWN	Direction.DOWN
		else ifx key == .LEFT	Direction.LEFT
		else .NONE;
}
Cell :: enum u8 {
	EMPTY	:: 0;
	SNAKE	:: 1;
	FRUIT	:: 2;
}
game_state : enum u8 {
	START	:: 0;
	GAME	:: 1;
	END 	:: 2;
}

stop_main := false;
grid_size :: ivec2.{21, 21};
#assert grid_size.x >= 9;

current_dir := Direction.RIGHT;

snake_points : Queue(ivec2);
game_map : []Cell;
game_canvas : Canvas;
// empty_cells : Table(ivec2, void, ivec2_hash, operator==);

move :: (stretch := false) {
	head_new := last(snake_points);
	if current_dir == {
		case .UP;	head_new += .{ 0, -1};
		case .RIGHT;head_new += .{ 1,  0};
		case .DOWN;	head_new += .{ 0,  1};
		case .LEFT;	head_new += .{-1,  0};
	}
	if !point_inside(head_new, .{size = grid_size}) || map_get(head_new) == .SNAKE {
		game_state = .END;
		score = snake_points.count - 4;
		best_score = max(best_score, score);
		return;
	}
	if !stretch && map_get(head_new) != .FRUIT {
		tail := pop(*snake_points);
		map_set(tail, .EMPTY);
	}
	if map_get(head_new) == .FRUIT {
		spawn_fruit();
	}
	push(*snake_points, head_new);
	map_set(head_new, .SNAKE);
}
map_set :: (pos : ivec2, cell : Cell) {
	game_map[pos.x + pos.y * grid_size.x] = cell;
}
map_get :: (pos : ivec2) -> Cell {
	return game_map[pos.x + pos.y * grid_size.x];
}
restart :: () {
	finalize();
	init();
}

score := 0;
best_score := 0;

FRUIT_COUNT :: #run max(1, grid_size.x * grid_size.y / 100);

spawn_fruit :: () -> bool {
	if snake_points.count + FRUIT_COUNT >= grid_size.x * grid_size.y return false;
	ATTEMPTS :: 10;
	for 1..ATTEMPTS {
		pos := ivec2.{xx(random_get() % xx grid_size.x), xx(random_get() % xx grid_size.y)};
		if map_get(pos) == .EMPTY {
			map_set(pos, .FRUIT);
			return true;
		}
	}
	for i : 0..grid_size.y * grid_size.x - 1 {
		if game_map[i] == .EMPTY {
			game_map[i] = .FRUIT;
			return true;
		}
	}
	return false;
}

init :: () {
	score = 0;
	current_dir = .RIGHT;

	game_map = NewArray(grid_size.x * grid_size.y, Cell);
	center := ivec2.{grid_size.x / 2, grid_size.y / 2};

	push(*snake_points, center);
	map_set(center, .SNAKE);

	for i : 1..3 move(true);

	for i : 1..FRUIT_COUNT spawn_fruit();

	resize_clear(*game_canvas, .{size = .{grid_size.x * 2, grid_size.y}}, make_char(#char " ", background = .GREEN));
}
finalize :: () {
	deinit(*snake_points);
	deinit(*game_canvas);
	array_free(game_map);
}

CHAR_EMPTY :: #run make_char(#char" ", background = .GREEN);
CHAR_SNAKE :: #run make_char(#char" ", background = .BRIGHT_WHITE);
CHAR_FRUIT :: #run make_char(#char" ", background = .BRIGHT_RED);

draw :: () {
	if #complete game_state == {
		case .START;
		ks_mode_reset();
		ks_clear_screen();
		ks_print(.{0, 0}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "press ENTER to start");

		case .GAME;
		if inside(game_canvas.zone, terminal_state.size) {
			for y : 0..grid_size.y-1 {
				for x : 0..grid_size.x-1 {
					cell := map_get(.{x, y});
					char := ifx cell == .EMPTY CHAR_EMPTY else ifx cell == .SNAKE CHAR_SNAKE else CHAR_FRUIT;
					c_putchar(*game_canvas, char, .{x * 2, y});
					c_putchar(*game_canvas, char, .{x * 2 + 1, y});
				}
			}
			if game_canvas.force_full_refresh {
				ks_mode_reset();
				ks_clear_screen();

				delta := terminal_state.size - game_canvas.zone.size;
				game_canvas.zone.corner = .{delta.x / 2, delta.y / 2};
			}
			ks_draw_canvas(*game_canvas);
		} else {
			ks_mode_reset();
			ks_clear_screen();
			ks_print(.{0, 0}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "screen too small!");
		}

		case .END;
		ks_mode_reset();
		ks_clear_screen();
		ks_print(.{0, 0}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "game over, score = %", score);
		ks_print(.{0, 1}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "best score = %", best_score);
		ks_print(.{0, 2}, make_graphics_mode(foreground = .BLACK, background = .BRIGHT_GREEN), "press ENTER to restart");
	}
}

#import "Random";
