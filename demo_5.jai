demo_5 :: () {
	master : UI_Master;
	popup_manager : UI_Popup_Manager;
		background : UI_Group = .{box_type = .NO_BORDER};
			lines : [..]string;
			text_buf : UI_Text_Buf;
			btn_add : UI_Button = .{text = "add fruit"};
		select_popup : UI_Group;
			btn_apple   : UI_Button = .{text = "apple"};
			btn_apricot : UI_Button = .{text = "apricot"};

	select_popup_scene := UI_Popup.{*select_popup, *btn_apple, .{20, 5}};

	add_fruit :: (lines : *[..]string, text_buf : *UI_Text_Buf, name : string) #expand {
		array_add(lines, name);	
		text_buf.lines = <<lines;
	}

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

	struct_lambda(#code {btn_add.on_click; popup_manager; select_popup_scene; ()->(); {
		push(_popup_manager, <<_select_popup_scene);
	}});
	struct_lambda(#code {btn_apple.on_click; popup_manager; lines; text_buf; ()->(); {
		add_fruit(_lines, _text_buf, "apple");
		pop(_popup_manager);
	}});
	struct_lambda(#code {btn_apricot.on_click; popup_manager; lines; text_buf; ()->(); {
		add_fruit(_lines, _text_buf, "apricot");
		pop(_popup_manager);
	}});

	set_background(*popup_manager, .{*background, *btn_add});
	set_scene(*master, .{*popup_manager, *btn_add});

	use_ks_curses();
	// x := ks_getch();
	io_cycle(*master);
}
// #scope_file
// Scene_Fruit_List :: struct {
// 	base : UI_Scene;

// 	background : UI_Group = .{box_type = .NO_BORDER};
// 	lines : [..]string;
// 	text_buf : UI_Text_Buf;
// 	btn_add : UI_Button = .{text = "add fruit"};
// }
// make_scene_main :: () -> Scene_Main, UI_Scene #expand {

// }
// clear_scene_main :: (using scene_main : *Scene_Main) {

// }
