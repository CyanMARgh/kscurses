Canvas :: struct {
	pixels_buf : []Char;
	size : ivec2;
	screen := false;

	#if DEBUG {
		valid := true;
	}
}
be_valid :: inline () #expand {
	#if DEBUG {
		assert(`valid);
	}
}
Screen_Canvas :: struct {
	#as base : Canvas = .{screen = true};

	pixels_last_draw : []Char;
	links : []Link;
	diff_count := 0;
	force_full_refresh := true;
	Link :: struct { prev, next : s32; }
}
deinit :: (using canvas : *Canvas) {
	be_valid();
	array_free(pixels_buf);
	if screen {
		using cast(*Screen_Canvas)canvas;
		array_free(pixels_last_draw);
		array_free(links);
	}
	valid = false;
}

resize :: (using canvas : *Canvas, _size : ivec2) {
	be_valid();
	new_size := ivec2.{max(_size.x, 0), max(_size.y, 0)};
	count, new_count := size.x * size.y, new_size.x * new_size.y;
	size = new_size;
	if count != new_count {
		array_free(pixels_buf);
		pixels_buf = NewArray(new_count, Char);
		if screen {
			using cast(*Screen_Canvas)canvas;
			array_free(pixels_last_draw);
			pixels_last_draw = NewArray(new_count, Char);

			array_free(links);
			links = NewArray(new_count + 1, Link);
			links[new_count] = .{xx new_count, xx new_count};
		
			force_full_refresh = true;			
		}
	}
}
c_putchar :: (using canvas : *Canvas, char : Char, pos : ivec2) {
	if !char.code || !point_inside_zone(pos, size) return;

	ipos := pos.x + pos.y * size.x;

	if screen {
		using cast(*Screen_Canvas)canvas;
		count := size.x * size.y;

		old_char := pixels_last_draw[ipos];
		pixels_buf[ipos] = char;

		if links[ipos].prev == -1 {
			assert(links[ipos].next == -1, "(0)");
			if old_char != char {
				links[ipos] = .{links[count].prev, xx count};
				links[links[count].prev].next = ipos;
				links[count].prev = ipos;
				diff_count += 1;
			}
		} else {
			if old_char == char {
				nbs := links[ipos];
				assert(links[nbs.prev].next == ipos && links[nbs.next].prev == ipos, "(1)");
				links[nbs.prev].next = nbs.next;
				links[nbs.next].prev = nbs.prev;
				links[ipos] = .{-1, -1};
				diff_count -= 1;
			}
		}

	}
	pixels_buf[ipos] = char;
}

c_clear :: (using canvas : *Canvas, filler := Char.{}, $partial := false, zone := Ibox2.{}) {
	be_valid();
	#if partial {
		assert(!screen);
		p0 := zone.corner;
		p1 := zone.corner + zone.size;

		p0 = .{max(p0.x, 0), max(p0.y, 0)};
		p1 = .{min(p1.x, size.x), min(p1.y, size.y)};
	} else {
		p0, p1 : ivec2 = .{0, 0}, size;
	}

	for y : p0.y..p1.y-1 {
		for x : p0.x..p1.x-1 {
			char := filler;
			c_putchar(canvas, char, .{x, y});
		}
	}
}

c_fill :: (using canvas : *Canvas, fill_function : (coord : ivec2, zone_size : ivec2) -> Char, $partial := false, zone := Ibox2.{}) {
	be_valid();
	#if partial {
		assert(!screen);
		p0 := zone.corner;
		p1 := zone.corner + zone.size;
	} else {
		p0, p1 : ivec2 = .{0, 0}, size;
	}

	for y : p0.y..p1.y-1 {
		for x : p0.x..p1.x-1 {
			char := fill_function(.{x, y}, size);
			c_putchar(canvas, char, .{x, y});
		}
	}
}

// c_fill :: (using canvas : *Canvas, fill_function : (coord : ivec2, zone_size : ivec2) -> Char, $partial := false, zone := Ibox2.{}) {
// 	c_fill_general(canvas, partial, zone, 
// 		#code fill_function(.{x, y}, zone)
// 	);
// }
//override only c_putchar


// // add *void to fill_function

b_draw_canvas :: (builder : *String_Builder, using canvas : *Canvas) {
	if screen {
		count := size.x * size.y;
		using cast(*Screen_Canvas)canvas;
		if force_full_refresh || diff_count * 4 > size.x * size.y {
		// if true {
			i := 0;
			for y : 0..size.y-1 {
				b_move_cursor(builder, .{0, y});
				for x : 0..size.x-1 {
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

				pos := ivec2.{xx(current % size.x), xx(current / size.x)};
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
	} else {
		assert(false);
		// i := 0;
		// for y : 0..size.y-1 {
		// 	b_move_cursor(builder, .{0, y});
		// 	for x : 0..size.x-1 {
		// 		b_putchar(builder, pixels_buf[i]);
		// 		i += 1;
		// 	} 
		// }
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
	if !point_inside_zone(pos, size) return .{code = 0};
	current := pos.x + pos.y * size.x;
	return pixels_buf[current];
}

ks_draw_canvas :: (canvas : *Canvas) {
	builder := String_Builder.{allocator = temp};
	b_draw_canvas(*builder, canvas);
	ks_write(builder_to_string(*builder,, allocator = temp));
}