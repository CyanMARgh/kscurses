demo_10 :: () {
	group : UI_Group;
		table : UI_Table = .{
			columns = 3
		};
	set_sub_elements(*group, 
		.{*table, .{40, 20, 0, 0}}
	);	

	add_line(*table, "grzegorz", "brzeczyszczykiewich", "-");
	add_line(*table, "jon", "smith", "-");
	add_line(*table, "ivan", "ivanov", "ivanovich");
	defer deinit(*table);

	set_main_scene(.{*group, *table});

	use_ks_curses();
	run_multithread_ui();
}