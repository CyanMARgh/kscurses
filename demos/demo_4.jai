demo_4 :: () {
	scene_manager : UI_Scene_Manager;
		S0 : UI_Group;
			btn_to_s1 : UI_Button = .{text = "swtch scene!"};
			g0, g1 : UI_Group;
				e00, e10     , e30 : UI_Elem;
				e01, e11, e21, e31 : UI_Elem;
				e20 : UI_Button = .{text = "click!"};
			text_buf : UI_Text_Buf;
			select_list : UI_Select_List;
			draw_counter : UI_Text_Buf;
		// S1 : UI_Group;
		S1 : UI_Scalable_Group;
			btn_to_s0 : UI_Button = .{text = "swtch scene!"};

	{
		lines : [4]string = .["first line", "second line", "", "third line"];
		text_buf.lines = lines;
	}
	{
		lines : [1]string = .[""];
		draw_counter.lines = lines;
	}

	struct_lambda(#code {e20.on_click; text_buf; ()->(); {
		_text_buf.lines[2] = "click!";
	}}); 
	struct_lambda(#code {__ui_master.before_draw; draw_counter; ()->(); {
		_draw_counter.lines[0] = tprint("% chars", __write_counter);
	}}); 
	struct_lambda(#code {btn_to_s1.on_click; scene_manager; ()->(); {
		switch_scene(_scene_manager, 1);
	}}); 
	struct_lambda(#code {btn_to_s0.on_click; scene_manager; ()->(); {
		switch_scene(_scene_manager, 0);
	}});

	select_list.options = .["option 1", "option 2", "option 3", "another option", "option #5", "option #7", "banana", "option #6"];
	init(*select_list, false); defer deinit(*select_list);

	set_sub_elements(*g0, 
		.{*e00, .{8, 4, 0, 0}},
		.{*e10, .{8, 4, 8, 0}},
		.{*e01, .{8, 4, 0, 4}},
		.{*e11, .{8, 4, 8, 4}},
	);

	g1.box_type = .NO_BORDER;
	set_sub_elements(*g1, 
		.{*e20, .{8, 4, 1, 1}},
		.{*e30, .{8, 4, 9, 1}},
		.{*e21, .{8, 4, 1, 5}},
		.{*e31, .{8, 4, 9, 5}},
	);
	set_sub_elements(*S0,
		.{*g0, .{18, 10,  0,  0}},
		.{*g1, .{18, 10, 18,  0}},
		.{*btn_to_s1, .{15, 5, 36,  2}},
		.{*text_buf, .{54, 10,  0, 10}},
		.{*select_list, .{20, 6,  0, 20}},
		.{*draw_counter, .{15, 3, 0, 26}}
	);
	// set_sub_elements(*S1,
	// 	.{*btn_to_s0, .{15, 5, 0,  0}}
	// );
	set_sub_elements(*S1, 
		.{*btn_to_s0, .{ metrics = .{15, 5, 0, 0} }}
	);

	set_sub_elements(*scene_manager,
		.{*S0, *e00},
		.{*S1, *btn_to_s0}
	);

	link_grid(.{4, 2}, 
		*e00, *e10, *e20, *e30,
		*e01, *e11, *e21, *e31
	);
	link_to_right(*btn_to_s1, *e30, *e31, *g1);

	link_to_outer(*g0, *e00, *e10, *e01, *e11);
	link_to_outer(*g1, *e20, *e30, *e21, *e31);
	link_row(*g0, *g1);

	link_to_bottom(*text_buf, *e01, *e11, *e21, *e31, *g0, *g1, *btn_to_s1);

	link_tb(*text_buf, *select_list);

	set_main_scene(.{*scene_manager, *e00});

	use_ks_curses();
	// log("some log!");
	// run_singlethread_ui();
	run_multithread_ui();
}
