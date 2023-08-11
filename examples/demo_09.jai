demo_09 :: () {
	
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

Step :: struct {
	pos : ivec2;
	player : u8;
}
Cell :: enum u8 { N :: 0; X :: 1; O :: 2; }
Board :: struct {
	alive : [2]bool = .[true, true];
	current_player : u8;

	size, cursor : ivec2;
	cells : []Cell;
	history :: [..]Step;
}
at :: (using board : Board, ivec2 : pos) -> *Cell {
	assert(pos.x >= 0 && pos.y >= 0 && pos.x < size.x && pos.y < size.y);
	return *(cells[pos.x + pos.y * size.x]);
}
make_board :: (size := ivec2.{3, 3}) -> Board {
	board := Board.{size = size};
	board.cells = NewArray(size.x * size.y, Cell);

	return board;
}
move :: (using board : *Board, dir : Direction) {
	if dir == {
		case .LEFT;
		if cursor.x > 0 then cursor.x -= 1;
		case .UP;
		if cursor.y > 0 then cursor.y -= 1;
		case .RIGHT;
		if cursor.x < size.x - 1 then cursor.x += 1;
		case .DOWN;
		if cursor.y < size.y - 1 then cursor.y += 1;
	}
}
click :: (using board : *Board, player_me : u8) -> switch_player:bool, game_ended:bool {
	if current_player != player_me return false, false;
	if !alive[player_me] return false, false;
	cell := at(board, cursor);
	if <<cell == .N {
		<<cell = ifx player_me == 0 then .X else .O; 
		// check if game ended
		current_player = (player_me + 1) % 2;
		game_ended := false;
		return true, game_ended;
	}
	return false, false;
}
apply :: (using board : *Board, step : Step) {
	cell := at(board, step.pos);
	assert(<<cell == .N);
	<<cell = ifx step.player == 0 then .X else .O;
	current_player = (current_player + 1) % 2;

	array_add(*history, step);
}
undo :: (using board : *Board) {
	step := pop(*history);
	cell := at(board, step.pos);
	assert(<<cell == (ifx step.player == 0 then .X else .O));

	current_player = (current_player + 1) % 2;
	<<cell = .N;
}
get_possible_steps :: (using board : *Board) -> []Step {
	result : [..]Step;
	result.allocator = temp;
	i := 0;
	for y : 0..size.y-1 {
		for x : 0..size.x-1 {
			if cells[i] == .N {
				array_add(*result, .{.{xx x, xx y}, current_player});
			}
			i += 1;
		}
	}
	return result;
}
eval :: (using board : *Board) -> int {
	//================
	_at :: (x : int, y : int) #expand {
		return <<at(board, .{x, y});
	}
	line :: (c1 : Cell, c2 : Cell, c3 : Cell) #expand {
		if c1 == .X && c2 == .X && c3 == .X `return 1;
		if c1 == .O && c2 == .O && c3 == .O `return -1;
	}
	for y : 0..size.y-1 {
		for x : 0..size.x-3 {
			line(<<at(board, .{x, y}))
		}
	}

	return 0;
}
get_optimal_step :: (using board : *Board) -> Step {
	//=======
}

main_board : Board;
PLAYER_ME :: 0;


// signal_to_opponent : enum u8 { NONE; PASS; STOP; };
// sem_signal : Semaphore;

// cycle_opponent :: (thread : *Thread) {

// } 