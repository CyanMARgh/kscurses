MAX_ATTRS :: 7;
Graphics_Mode :: struct {
	foreground : Color;
	background : Color;
	attr_flags : enum_flags u8 {
		F_BOLD 			:: 0x1; 
		F_DIM 			:: 0x2; 
		F_ITALIC 		:: 0x4; 
		F_UNDERLINE 	:: 0x8; 
		F_BLINKING 		:: 0x10; 
		F_INVERSE 		:: 0x20; 
		F_STRIKETHROUGH :: 0x40; 
	}
	// attrs : [MAX_ATTRS]bool;
	// 0 - bold (on/off/keep)
	// 1 - dim/faint
	// 2 - italic
	// 3 - underline
	// 4 - blinking
	// 5 - inverse
	// 6 - strikethrough
	fcol256 : u8;
	bcol256 : u8;
}
Color :: enum u8 {
	RESET 			:: 0;
	DEFAULT 		:: 39;
	COLOR256		:: 38;

	BLACK 			:: 30;
	RED 			:: 31;
	GREEN 			:: 32;
	YELLOW 			:: 33;
	BLUE 			:: 34;
	MAGENTA 		:: 35;
	CYAN 			:: 36;
	WHITE 			:: 37;

	BRIGHT_BLACK 	:: 90;
	BRIGHT_RED 		:: 91;
	BRIGHT_GREEN 	:: 92;
	BRIGHT_YELLOW 	:: 93;
	BRIGHT_BLUE 	:: 94;
	BRIGHT_MAGENTA 	:: 95;
	BRIGHT_CYAN 	:: 96;
	BRIGHT_WHITE 	:: 97;
}
Attr :: enum u8 {
	BOLD 				:: 1;
	DIM 				:: 2;
	ITALIC 				:: 3;
	UNDERLINE			:: 4;
	BLINKING			:: 5;
	INVERSE				:: 7;
	STRIKETHROUGH		:: 9;

	BOLD_AND_DIM_OFF	:: 22;
	ITALIC_OFF			:: 23;
	UNDERLINE_OFF		:: 24;
	BLINKING_OFF		:: 25;
	INVERSE_OFF			:: 27;
	STRIKETHROUGH_OFF 	:: 29;
}

make_graphics_mode :: (foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, blinking := false, inverse := false, strikethrough := false, fcol256 :u8= 0, bcol256 :u8= 0) -> Graphics_Mode {
	result : Graphics_Mode;

	result.foreground = foreground;
	result.background = xx (background + 10);

	if bold 			result.attr_flags |= .F_BOLD;
	if dim  			result.attr_flags |= .F_DIM;
	if italic 			result.attr_flags |= .F_ITALIC;
	if underline 		result.attr_flags |= .F_UNDERLINE;
	if blinking 		result.attr_flags |= .F_BLINKING;
	if inverse 			result.attr_flags |= .F_INVERSE;
	if strikethrough	result.attr_flags |= .F_STRIKETHROUGH;
	//========

	// result.attrs[0] = bold;
	// result.attrs[1] = dim;
	// result.attrs[2] = italic;
	// result.attrs[3] = underline;
	// result.attrs[4] = blinking;
	// result.attrs[5] = inverse;
	// result.attrs[6] = strikethrough;
	result.fcol256 = fcol256;
	result.bcol256 = bcol256;

	return result;
}

Char :: struct {
	code : u32;
	#place code;
	codes : [4]u8 = ---;
	mode : Graphics_Mode;
}
make_char :: (code : u32, foreground := Color.DEFAULT, background := Color.DEFAULT, bold := false, dim := false, italic := false, underline := false, blinking := false, inverse := false, strikethrough := false, fcol256 :u8= 0, bcol256 :u8= 0) -> Char {
	return .{code = code, mode = make_graphics_mode(foreground, background, bold, dim, italic, underline, blinking, inverse, strikethrough, fcol256, bcol256)};
}
length :: inline (c : Char) -> u8 {
	return length_code(c.code);
}
operator== :: (c1 : Char, c2 : Char) -> bool {
	return c1.code == c2.code && c1.mode == c2.mode;
}
operator== :: (m1 : Graphics_Mode, m2 : Graphics_Mode) -> bool {
	if m1.foreground != m2.foreground return false;
	if m1.background != m2.background return false;
	if m1.fcol256 != m2.fcol256 return false;
	if m1.bcol256 != m2.bcol256 return false;
	if m1.attr_flags != m2.attr_flags return false;
	return true;
}

find_best_char :: (p : Vector3, use_mix : bool) -> Char {
	cast_255 :: (x : float) -> s32 {
		return clamp(cast(s32)(x * 255 + .5), 0, 255);
	}
	return find_best_char(ivec3.{cast_255(p.x), cast_255(p.y), cast_255(p.z)}, use_mix);
}
find_best_char :: (p : u8vec3, use_mix : bool) -> Char {
	return find_best_char(cast_vec(s32, p), use_mix);
}
find_best_char :: (_p : ivec3, use_mix : bool) -> Char {
	p := _p;
	to_6level :: (x : s32) -> u8, s32 {
		a := u8.[
			0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 1, 1, 1, 1,
			1, 1, 1, 1, 2, 2, 2, 2,
			2, 2, 2, 2, 2, 2, 2, 3,
			3, 3, 3, 3, 3, 3, 3, 3,
			3, 4, 4, 4, 4, 4, 4, 4,
			4, 4, 4, 5, 5, 5, 5, 5,
		][clamp(x, 0, 255) >> 2];
		return a, s32.[0, 87, 135, 175, 215, 255][a];
	}

	to_6level :: (v : ivec3) -> u8vec3, ivec3, dist:int {
		i : u8vec3;
		h : ivec3;
		i.x, h.x = to_6level(v.x);
		i.y, h.y = to_6level(v.y);
		i.z, h.z = to_6level(v.z);
		w := v - h;
		return i, h, w.x * w.x + w.y * w.y + w.z * w.z;
	}
	col_code :: (v : u8vec3) -> u8 { return 16 + 36 * v.x + 6 * v.y + v.z; }

	b_6, b_256 := to_6level(p);
	code_00, code_25, code_50, code_75 := #run utf8(" "), #run utf8("░"), #run utf8("▒"), #run utf8("▓");

	result := make_char(
		code_00,
		foreground = .COLOR256,
		background = .COLOR256,
		bcol256 = col_code(b_6)
	);

	if use_mix {
		f_6_25, f_256_25, dist_25 := to_6level(p * 4 - b_256 * 3);
		f_6_50, f_256_50, dist_50 := to_6level(p * 2 - b_256);
		f_6_75, f_256_75, dist_75 := to_6level((p * 4 - b_256) / 3);


		if dist_25 > dist_50 then f_6_25, code_25, dist_25 = f_6_50, code_50, dist_50;
		if dist_25 > dist_75 then f_6_25, code_25, dist_25 = f_6_75, code_75, dist_75;

		result.code = code_25;
		result.mode.fcol256 = col_code(f_6_25);
	}
	return result;
}

#scope_file
#import "Math";