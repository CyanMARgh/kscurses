Canvas :: struct {
	zone : Ibox2;

	count : int;
	pixels_last_draw : []Char;
	pixels_buf : []Char;
	links : []Link;

	diff_count := 0;
	force_full_refresh := true;

	Link :: struct { prev, next : s32; }
}

deinit :: (using canvas : *Canvas) {
	array_free(pixels_last_draw);
	array_free(pixels_buf); pixels_buf = .[];
	array_free(links);
}
resize_clear :: (using canvas : *Canvas, new_zone : Ibox2, filler := Char.{}) {
	if new_zone != zone {
		array_free(pixels_last_draw);
		array_free(pixels_buf);
		array_free(links);

		zone = new_zone;
		count = zone.width * zone.height;

		pixels_last_draw = NewArray(count, Char);
		pixels_buf = NewArray(count, Char);
		links = NewArray(count + 1, Link);
		links[count] = .{xx count, xx count};
	
		if filler != .{} then {
			for * pixels_buf {
				<<it = filler;
			}
		}
		links[count] = .{-1, -1};

		force_full_refresh = true;
	} else {
		for y : 0..zone.height-1 {
			for x : 0..zone.width-1 {
				c_putchar(canvas, filler, .{xx x, xx y});
			}
		}		
	}
}
// add *void to fill_function
resize_fill :: (using canvas : *Canvas, new_zone : Ibox2, fill_function : (coord : ivec2, zone : Ibox2) -> Char) {
	if zone != new_zone {
		array_free(pixels_last_draw);
		array_free(pixels_buf);
		array_free(links);

		zone = new_zone;
		count = zone.width * zone.height;

		pixels_last_draw = NewArray(count, Char);
		pixels_buf = NewArray(count, Char);
		links = NewArray(count + 1, Link);
		links[count] = .{xx count, xx count};
		force_full_refresh = true;
	}

	c_fill(canvas, fill_function);
	// i := 0;
	// for y : 0..zone.height-1 {
	// 	for x : 0..zone.width-1 {
	// 		pixels_buf[i] = fill_function(.{x, y}, zone);
	// 		i += 1;
	// 		diff_count += 1;
	// 	}
	// }

	// for * links {
	// 	<<it = .{-1, -1};
	// }
}
b_draw_canvas :: (builder : *String_Builder, using canvas : *Canvas) {
	if force_full_refresh || diff_count * 4 > zone.width * zone.height {
		i := 0;
		for y : 0..zone.height-1 {
			b_move_cursor(builder, zone.corner + ivec2.{0, y});
			for x : 0..zone.width-1 {
				b_putchar(builder, pixels_buf[i]);
				pixels_last_draw[i] = pixels_buf[i];
				links[i] = .{-1, -1};
				i += 1;
			} 
		}
	} else {
		last_pos := ivec2.{-1, -1};
		current := links[count].next;
		I := 0;

		while current != count {
			assert(I < count);
			assert(current >= 0);

			pos := ivec2.{xx(current % zone.width), xx(current / zone.width)} + zone.corner;
			if pos.x != last_pos.x + 1 || pos.y != last_pos.y {
				b_move_cursor(builder, pos);
			}
			b_putchar(builder, pixels_buf[current]);
			pixels_last_draw[current] = pixels_buf[current];

			next := links[current].next;
			links[current] = .{-1, -1};
			current = next;
			last_pos = pos;
			I += 1;
		}
	}

	diff_count = 0;
	force_full_refresh = false;
	links[count] = .{xx count, xx count};
}
c_putchar :: (using canvas : *Canvas, pixel : Char, pos_local : ivec2) {
	// pos_local := pos - zone.corner;
	if !pixel.code || !point_inside_zone(pos_local, zone.size) return;
	// log("pos_local: %, zone : %\n", pos_local, zone);
	current := pos_local.x + pos_local.y * zone.width;

	c_last_draw := pixels_last_draw[current];
	pixels_buf[current] = pixel;

	if links[current].prev == -1 {
		assert(links[current].next == -1, "(0)");
		if c_last_draw != pixel {
			links[current] = .{links[count].prev, xx count};
			links[links[count].prev].next = current;
			links[count].prev = current;
			diff_count += 1;
		}
	} else {
		if c_last_draw == pixel {
			nbs := links[current];
			assert(links[nbs.prev].next == current && links[nbs.next].prev == current, "(1)");
			links[nbs.prev].next = nbs.next;
			links[nbs.next].prev = nbs.prev;
			links[current] = .{-1, -1};
			diff_count -= 1;
		}
	}
}
c_printl_ascii :: (canvas : *Canvas, coord : ivec2, mode : Graphics_Mode, str : string) {
	x, y := coord.x, coord.y;
	for c, i : cast([]u8)str {
		assert(!(c & 0x80), "str = %\n, c, i = %, %\n", str, c, i);
		if c == #char"\n" {
			y += 1;
			x = coord.x;
		} else {
			c_putchar(canvas, .{code = xx c, mode = mode}, .{x, y});
			x += 1;
		}
	}
}

c_print_ascii :: (canvas : *Canvas, coord : ivec2, mode : Graphics_Mode, fmt : string, args : ..Any) {
	c_printl_ascii(canvas, coord, mode, tprint(fmt, ..args));
}

at :: (using canvas : Canvas, pos : ivec2) -> Char {
	current := pos.x + pos.y * zone.width;
	return pixels_buf[current];
}

c_fill :: (using canvas : *Canvas, fill_function : (coord : ivec2, zone : Ibox2) -> Char) {
	for y : 0..zone.height-1 {
		for x : 0..zone.width-1 {
			char := fill_function(.{x, y}, zone);
			c_putchar(canvas, char, .{x, y});
		}
	}
	// i := 0;
	// for y : 0..zone.height-1 {
	// 	for x : 0..zone.width-1 {
	// 		pixels_buf[i] = fill_function(.{x, y}, zone);
	// 		i += 1;
	// 		diff_count += 1;
	// 	}
	// }
	// refresh_all = true;
}
ks_draw_canvas :: (canvas : *Canvas) {
	builder := String_Builder.{allocator = temp};
	b_draw_canvas(*builder, canvas);
	ks_write(builder_to_string(*builder,, allocator = temp));
}


