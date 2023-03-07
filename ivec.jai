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

Gen_Vec3 :: struct(T : Type) {
	x, y, z : T;
}
operator+ :: (a : Gen_Vec3($T), b : Gen_Vec3(T)) -> Gen_Vec3(T) {
	return .{a.x + b.x, a.y + b.y, a.z + b.z};
}
operator* :: (a : Gen_Vec3($T), b : T) -> Gen_Vec3(T) {
	return .{a.x * b, a.y * b, a.z * b};
}
operator- :: (a : Gen_Vec3($T), b : Gen_Vec3(T)) -> Gen_Vec3(T) {
	return .{a.x - b.x, a.y - b.y, a.z - b.z};
}
operator== :: (a : Gen_Vec3($T), b : Gen_Vec3(T)) -> bool {
	return a.x == b.x && a.y == b.y && a.z == b.z;
}
cast_vec :: ($T2 : Type, v : Gen_Vec3($T1)) -> Gen_Vec3(T2) {
	return .{cast(T2)v.x, cast(T2)v.y, cast(T2)v.z};
}
ivec3 :: Gen_Vec3(s32);
u8vec3 :: Gen_Vec3(u8);

Ibox2 :: struct {
	width, height, left, top : s32;
	#place width;
	size : ivec2;
	#place left;
	corner : ivec2;
}
inside :: (inner : Ibox2, outer : Ibox2) -> bool {
	icorner2 := inner.corner + inner.size;
	ocorner2 := outer.corner + outer.size;
	return
		inner.corner.x >= outer.corner.x && inner.corner.y >= outer.corner.y &&
		icorner2.x <= ocorner2.x && icorner2.y <= ocorner2.y;
}
inside :: (inner : Ibox2, outer : ivec2) -> bool {
	icorner2 := inner.corner + inner.size;
	return
		inner.corner.x >= 0 && inner.corner.y >= 0 &&
		icorner2.x <= outer.x && icorner2.y <= outer.y;
}
inside :: (inner : ivec2, outer : ivec2) -> bool {
	return inner.x <= outer.x && inner.y <= outer.y;
}