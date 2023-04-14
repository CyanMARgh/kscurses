Canvas :: struct {
	zone : Ibox2;

	count : int;
	pixels_last_draw : []Char;
	pixels_buf : []Char;
	links : []Link;

	diff_count := 0;
	refresh_all := false;

	Link :: struct { prev, next : s32; }
}

deinit :: (using canvas : *Canvas) {
	array_free(pixels_last_draw);
	array_free(pixels_buf); pixels_buf = .[];
	array_free(links);
}
resize_clear :: (using canvas : *Canvas, new_zone : Ibox2, filler := Char.{}) {
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
	for i : 0..count-1 {
		links[count] = .{-1, -1};
	}
	refresh_all = true;
}
b_draw_canvas :: (builder : *String_Builder, using canvas : *Canvas) {
	if refresh_all {
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
		refresh_all = false;
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
	links[count] = .{xx count, xx count};
}
c_putchar :: (using canvas : *Canvas, pixel : Char, pos : ivec2) {
	if !point_inside(pos, zone) return;
	pos_local := pos - zone.corner;
	current := pos_local.x + pos_local.y * zone.width;

	c_last_draw := pixels_last_draw[current];
	pixels_buf[current] = pixel;

	if links[current].prev == -1 {
		assert(links[current].next == -1);
		if c_last_draw != pixel {
			links[current] = .{links[count].prev, xx count};
			links[links[count].prev].next = current;
			links[count].prev = current;
			diff_count += 1;
		}
	} else {
		if c_last_draw == pixel {
			nbs := links[current];
			assert(links[nbs.prev].next == current && links[nbs.next].prev == current);
			links[nbs.prev].next = nbs.next;
			links[nbs.next].prev = nbs.prev;
			links[current] = .{-1, -1};
			diff_count -= 1;
		}
	}
}

c_fill :: (using canvas : *Canvas, fill_function : (coord : ivec2, zone : Ibox2) -> Char) {
	i := 0;
	for y : 0..zone.height-1 {
		for x : 0..zone.width-1 {
			pixels_buf[i] = fill_function(.{x, y}, zone);
			i += 1;
			diff_count += 1;
		}
	}
	refresh_all = true;
}
ks_draw_canvas :: (canvas : *Canvas) {
	builder := String_Builder.{allocator = temp};
	b_draw_canvas(*builder, canvas);
	ks_write(builder_to_string(*builder, allocator = temp));
}


