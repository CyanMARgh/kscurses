anchor_lt :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{corner = zs0.corner, size = zs0.size};
}
anchor_rt :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{
		top = zs0.top,
		left = zs0.left + ss.x - ss0.x,
		size = zs0.size
	};
}
anchor_t :: (zs0 : Ibox2, ss0 : ivec2, ss : ivec2) -> Ibox2 {
	return .{
		top = zs0.top,
		left = zs0.left,
		width = zs0.width + ss.x - ss0.x,
		height = zs0.height
	};
}