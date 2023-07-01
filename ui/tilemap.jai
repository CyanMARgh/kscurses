UI_Tilemap :: struct {
	#as using base : UI_Elem = .{type = .TILEMAP};

	map_size : ivec2;
	map : []u64;
	tileset : *Tileset;

	background : Char; // if not set, then box's filler instead
}
Tileset :: struct {
	tile_size : ivec2;
	tiles_count : int;
	data : []Char;
	// code = 0                 ->  skip entire character
	// fcol/bcol = .DEFAULT     ->  skip foreground/background
}
c_draw_tile :: (canvas : *Canvas, tileset : *Tileset, offset : ivec2, id : u64, cutoff : Ibox2) {

}

