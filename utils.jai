// array_slice :: (array : []$T, left : int, right : int) -> []T {
// 	assert(left <= right && left >= 0 && right <= array.count);
// 	result : []T;
// 	result.data, result.count = array.data + left, right - left;
// 	return result;
// }

length_code :: inline (c : u64) -> u8 {
	for 0..7 {
		if !c return xx it;
		c >>= 8;
	}
	return 8;
}
utf8 :: (str : string) -> u32 {
	code : u32;
	assert(str.count <= 4);
	memcpy(*code, str.data, str.count);
	return code;
}
byteswap_64 :: (c : u64) -> u64 {
	c = ((0xFFFFFFFF00000000 & c) >> 32) | ((0x00000000FFFFFFFF & c) << 32);
	c = ((0xFFFF0000FFFF0000 & c) >> 16) | ((0x0000FFFF0000FFFF & c) << 16);
	c = ((0xFF00FF00FF00FF00 & c) >>  8) | ((0x00FF00FF00FF00FF & c) <<  8);
	return c;
}
byteswap_32 :: (c : u32) -> u32 {
	c = ((0xFFFF0000 & c) >> 16) | ((0x0000FFFF & c) << 16);
	c = ((0xFF00FF00 & c) >>  8) | ((0x00FF00FF & c) <<  8);
	return c;
}
char_bs :: (code : u32) -> u32 {
	l := length_code(code);
	return byteswap_32(code) >> ((8 - l) * 8);
}
utf8_bs :: (str : string) -> u32 {
	return char_bs(utf8(str));
}
arrow_code_to_ivec2 :: (key : Key, $swap_y := true) -> ivec2 {
	#if swap_y {
		return	 ifx key == .UP		ivec2.{ 0, -1}
			else ifx key == .RIGHT	ivec2.{ 1,  0}
			else ifx key == .DOWN	ivec2.{ 0,  1}
			else ifx key == .LEFT	ivec2.{-1,  0}
			else ivec2.{};		
	} else {
		return	 ifx key == .UP		ivec2.{ 0,  1}
			else ifx key == .RIGHT	ivec2.{ 1,  0}
			else ifx key == .DOWN	ivec2.{ 0, -1}
			else ifx key == .LEFT	ivec2.{-1,  0}
			else ivec2.{};		
	}
}
