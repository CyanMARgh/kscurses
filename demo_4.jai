demo_4 :: () {
	{
		lines :[4]string= .["first line", "second line", "", "third line"];
		text_buf.lines = lines;
	}
	{
		lines :[1]string= .[""];
		draw_counter.lines = lines;
	}

	e20.on_click = () { text_buf.lines[2] = "click!"; };

	master.before_draw = () { draw_counter.lines[0] = tprint("% chars", __write_counter); };

	btn_to_s1.on_click = () { switch_scene(*scene_manager, 1); };
	btn_to_s0.on_click = () { switch_scene(*scene_manager, 0); };

	select_list.options = .["option 1", "option 2", "option 3", "another option", "option #5", "option #7", "banana", "option #6"];

	set_sub_elements(*g0, 
		.{*e00, .{8, 4, 0, 0}},
		.{*e10, .{8, 4, 8, 0}},
		.{*e01, .{8, 4, 0, 4}},
		.{*e11, .{8, 4, 8, 4}},
	);

	g1.box_type = .NO_BORDER;
	set_sub_elements(*g1, 
		.{xx *e20, .{8, 4, 1, 1}},
		.{*e30, .{8, 4, 9, 1}},
		.{*e21, .{8, 4, 1, 5}},
		.{*e31, .{8, 4, 9, 5}},
	);
	set_sub_elements(*S0,
		.{xx *g0, .{18, 10,  0,  0}},
		.{xx *g1, .{18, 10, 18,  0}},
		.{xx *btn_to_s1, .{15, 5, 36,  2}},
		.{xx *text_buf, .{54, 10,  0, 10}},
		.{xx *select_list, .{20, 6,  0, 20}},
		.{xx *draw_counter, .{15, 3, 0, 26}}
	);
	set_sub_elements(*S1,
		.{xx *btn_to_s0, .{15, 5, 0,  0}}
	);
	set_sub_elements(*scene_manager,
		.{xx *S0, *e00},
		.{xx *S1, *btn_to_s0}
	);

	link_tb(*g0, xx *text_buf);
	link_tb(*g1, xx *text_buf);

	link_tb(*e11, xx *text_buf);
	link_tb(*e21, xx *text_buf);
	link_tb(*e31, xx *text_buf);
	link_tb(*e01, xx *text_buf);

	link_tb(*e00, *e01);
	link_tb(*e10, *e11);
	link_tb(*e20, *e21);
	link_tb(*e30, *e31);

	link_tb(*text_buf, *select_list);

	link_row(*e01, *e11, *e21, *e31, *btn_to_s1);
	link_row(*e00, *e10, *e20, *e30, *btn_to_s1);

	link_row(*g0, *g1);

	link_to_outer(*g0, *e00, *e10, *e01, *e11);
	link_to_outer(*g1, *e20, *e30, *e21, *e31);

	master.root = *scene_manager;
	set_active_recursive(*e00);

	use_ks_curses();
	io_cycle(*master);

}

#scope_file

master : UI_Master;

e00, e10     , e30 : UI_Elem;
e01, e11, e21, e31 : UI_Elem;

e20 : UI_Button = .{text = "click!"};

text_buf : UI_Text_Buf;
select_list : UI_Select_List;
draw_counter : UI_Text_Buf;

g0, g1 : UI_Group;

btn_to_s1 : UI_Button;

S0 : UI_Group;

btn_to_s0 : UI_Button = .{text = "swtch scene!"};

S1 : UI_Group;

scene_manager : UI_Scene_Manager;