History_Stack :: struct(
	Action_Type : Type,
	destructor : (obj : Action_Type) = default_destructor
){
	BUF_SIZE :: 100;
	buffer : [BUF_SIZE]Action_Type;
 	offset, current, saved : int;
}

deinit :: (using history_stack : *History_Stack) {
	guard(history);

	for i : 0..saved-1 {
		j := (i + offset) % BUF_SIZE;		
		destructor(buffer[offset]);
	}
	offset, current, saved = 0;
}

write :: (using history : *History_Stack, action : Edit_Action) {
	guard(history);

	for i : current..saved-1 {
		j := (i + offset) % BUF_SIZE;
		destructor(buffer[j]);
	}

	i0 := (offset + current) % BUF_SIZE;
	if current == BUF_SIZE {
		destructor(buffer[offset]);
		saved = current;
		offset = (offset + 1) % BUF_SIZE;
	} else {
		current += 1;
		saved = current;
	}
	i1 := (offset + current) % BUF_SIZE;
	assert(i0 == i1);
	buffer[i0] = action;
}


undo :: (using history : *History) -> bool, Action_Type {
	guard(history);
	action : Action_Type = ---;   
	if current == 0 return false, action;
	current -= 1;
	action = buffer[(current + offset) % BUF_SIZE];
	return true, action;
}
redo :: (using history : *History) -> bool, Action_Type {
	guard(history);
	action : Action_Type = ---;
	if current == saved return false, action;
	action = buffer[(current + offset) % BUF_SIZE];
	current += 1;
	return true, action;
}

#scope_file
default_destructor :: (obj : $T) { }

guard :: (using history : *History) #expand {
	check :: (using history : *History) {
		assert(0 <= current && current <= saved && saved <= BUF_SIZE);
		assert(0 <= offset && offset <= BUF_SIZE);		
	}
	check(history); defer check(history);
}