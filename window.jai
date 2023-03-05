Window :: struct {
	using zone : Ibox2;
	chars : []Char; 
}
clear :: (w : Window) {
	array_free(w.chars);
}
print_string_size : s64;
refresh :: (using w : *Window) {
	print_string_size = 0;
	
	builder := String_Builder.{allocator=temp};
	pix_id : u32 = 0;
	for y : 0..height-1 {
		prev_mode : Graphics_Mode; // TODO ???
		b_move_cursor(*builder, ivec2.{0, y} + corner);
		for x : 0..width-1 {
			C := chars[pix_id];
			b_mode_difference(*builder, prev_mode, C.mode);
			prev_mode = C.mode;
			char_str : string;
			char_str.data = xx *(C.code);
			char_str.count = length(C);
			append(*builder, char_str);
			pix_id += 1;
		}
		b_esc_m(*builder, 0);
	}
	str := builder_to_string(*builder, temp);
	print_string_size = str.count;
	ks_write(str);
	reset_temporary_storage();
}
make_window :: (_zone : Ibox2) -> Window {
	using w := Window.{zone = _zone};
	chars = NewArray(height * width, Char);
	return w;
}
fill :: (using w : *Window, fill_function : (coord : ivec2, size : ivec2) -> Char) {
	pix_id : u32 = 0;
	for y : 0..height-1 {
		for x : 0..width-1 {
			chars[pix_id] = fill_function(.{x, y}, size);
			pix_id += 1;
		}
	}
}
resize_no_fill :: (using w : *Window, _zone : Ibox2) {
	array_free(chars);
	zone = _zone;
	chars = NewArray(width * height, Char);
}
