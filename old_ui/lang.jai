// affects on line input & editor
Char_Type :: u64;
ENABLE_INPUT_RUS :: true;

is_rus :: (key : Key) -> bool {
	code := cast(u64) key;
	code_bs := char_bs(code);
	return	(code_bs >= #run utf8_bs("а")) && (code_bs <= #run utf8_bs("я")) ||
			(code_bs >= #run utf8_bs("А")) && (code_bs <= #run utf8_bs("Я")) ||
			code == utf8("ё") || code == utf8("Ё");
}

is_printable :: (key : Key) -> bool {
	code := cast(u64) key;
	return (code >= #char" " && code <= #char"~") || is_rus(key);
}
