demo_5 :: () {
	ks_init();
	// // print("\e[?1061l");
	// for i : 0..255 {
	// 	if i == 0 || i == 224 continue;
	// 	print("\e[%;101p", i);
	// }

	while 1 {
		code := ks_getch();
		// ks_write(tprint("[%/%]\n\r", formatInt(code, base = 16), cast(Key)code));		
		ks_write(tprint("[%]\n\r", code));		
	}

	ks_terminate();


	// print("[%] [%]", formatInt(code, base=16), cast(Keys)code);
}
