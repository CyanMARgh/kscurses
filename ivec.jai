ivec2 :: struct {
	x, y : s32;
}
operator+ :: (a : ivec2, b : ivec2) -> ivec2 {
	return .{a.x + b.x, a.y + b.y};
}
operator- :: (a : ivec2, b : ivec2) -> ivec2 {
	return .{a.x - b.x, a.y - b.y};
}
operator== :: (a : ivec2, b : ivec2) -> bool {
	return a.x == b.x && a.y == b.y;
}

Ibox2 :: struct {
	width, height, left, top : s32;
	#place width;
	size : ivec2;
	#place left;
	corner : ivec2;
}
