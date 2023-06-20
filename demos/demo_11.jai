demo_11 :: () {
	G : UI_Group;
	elements : [1]UI_Elem;
	set_sub_elements(*G,
		.{*elements[0], .{4, 5, 0, 0}}
	);

	set_main_scene(.{*G, *elements[0]});

	use_ks_curses();
	run_singlethread_ui();
}