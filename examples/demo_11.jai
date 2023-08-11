demo_11 :: () {	
	G : UI_Scalable_Group = .{box_type = .NO_BORDER};
	elements : [9]UI_Elem;
	little_one_on_top : UI_Elem;
	set_sub_elements(*G,
		.{*elements[0], .{14,  7,  2,  1, .ANCHOR_TL}},
		.{*elements[1], .{16,  1, 16,  7, .STRETCH_T}},
		.{*elements[2], .{14,  7,  2,  1, .ANCHOR_TR}},

		.{*elements[3], .{ 2,  8, 14,  8, .STRETCH_L}},
		.{*elements[4], .{16,  8, 16,  8, .STRETCH_C}},
		.{*elements[5], .{ 2,  8, 14,  8, .STRETCH_R}},

		.{*elements[6], .{14,  7,  2,  1, .ANCHOR_BL}},
		.{*elements[7], .{16,  1, 16,  7, .STRETCH_B}},
		.{*elements[8], .{14,  7,  2,  1, .ANCHOR_BR}},

		.{*little_one_on_top, .{10,  5,  0,  0, .CENTERIZE}}
	);

	link_grid(.{3, 3}, elements);

	set_main_scene(.{*G, *elements[0]});

	use_ks_curses();
	run_singlethread_ui();
}