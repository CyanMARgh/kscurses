demo_05 :: () {
	add_fruit :: (lines : *[..]string, text_buf : *UI_Text_Buf, name : string) #expand {
		array_add(lines, name);	
		text_buf.lines = <<lines;
	}

	select_popup_scene = UI_Popup.{*select_popup, *btn_apple, .{20, 5}};

	defer array_free(lines);
	add_fruit(*lines, *text_buf, "banana");

	set_sub_elements(*background,
		.{*text_buf, .{40, 20, 0, 0}},
		.{*btn_add, .{11, 3, 0, 20}}
	);
	set_sub_elements(*select_popup,
		.{*btn_apple, .{9, 3, 0, 0}},
		.{*btn_apricot, .{9, 3, 9, 0}}
	);
	link_lr(xx *btn_apple, xx *btn_apricot);

	btn_add.on_click.proc = (__data : *void) {
		push(*popup_manager, select_popup_scene);		
	};

	btn_apple.on_click.proc = (__data : *void) {
		add_fruit(*lines, *text_buf, "apple");
		pop(*popup_manager);
	};

	btn_apricot.on_click.proc = (__data : *void) {
		add_fruit(*lines, *text_buf, "apricot");
		pop(*popup_manager);
	};

	set_background(*popup_manager, .{*background, *btn_add});
	set_main_scene(.{*popup_manager, *btn_add});

	use_ks_curses();
	run_singlethread_ui();
	// run_multithread_ui();
}
#scope_file
popup_manager : UI_Popup_Manager;
	background : UI_Group = .{box_type = .NO_BORDER};
		lines : [..]string;
		text_buf : UI_Text_Buf;
		btn_add : UI_Button = .{text = "add fruit"};
	select_popup : UI_Group;
		btn_apple   : UI_Button = .{text = "apple"};
		btn_apricot : UI_Button = .{text = "apricot"};
select_popup_scene : UI_Popup;