Queue :: struct(Element_Type : Type) {
	buffer : []Element_Type;
	begin, count := 0;
}
pop :: (using queue : *Queue($Element_Type)) -> Element_Type, bool {
	elem : Element_Type;
	ok := true;
	if count {
		elem = buffer[begin];
		begin += 1;
		count -= 1;
	} else {
		ok = false;
	}
	return elem, ok;
}
get_space :: (using queue : *Queue($Element_Type), new_elements_count : int) {
	if begin + count + new_elements_count <= buffer.count return;
	if count <= begin && count + new_elements_count <= buffer.count {
 		memcpy(buffer.data, buffer.data + begin, size_of(Element_Type) * count);
 		begin = 0;
	} else {
		new_buf := NewArray(count + max(new_elements_count, count), Element_Type);
		memcpy(new_buf.data, buffer.data + begin, count * size_of(Element_Type));
		begin = 0;
		array_free(buffer);
		buffer = new_buf;
	}
}
push :: (using queue : *Queue($Element_Type), element : Element_Type) {
	get_space(queue, 1);
	assert(begin + count + 1 <= buffer.count);
	buffer[begin + count] = element;
	count += 1;
}
deinit :: (using queue : *Queue($Element_Type)) {
	array_free(buffer);
	<<queue = .{};
}
for_expansion :: (queue : Queue, body : Code, flags : For_Flags) #expand {
	for i : 0..queue.count-1 {
		`it_index := i;
		`it := queue.buffer[begin + i];

		#insert body;
	}
}
first :: (queue : Queue($Element_Type)) -> Element_Type, bool {
	result : Element_Type;
	if queue.count > 0 then result = queue.buffer[queue.begin];
	return result, queue.count > 0;
}
last :: (using queue : Queue($Element_Type)) -> Element_Type, bool {
	result : Element_Type;
	if queue.count > 0 then result = queue.buffer[queue.begin + queue.count - 1];
	return result, queue.count > 0;
}
