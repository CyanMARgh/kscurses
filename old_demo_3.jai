demo_3 :: () {
	set_elements(*ui_master, *left_box, *middle_box, *right_box, *select_list);
	defer reset_log();
	add_link_lr(*ui_master, 0, 1);
	add_link_lr(*ui_master, 1, 2);
	add_link_tb(*ui_master, 0, 3);
	terminal_state.on_resize = () {ks_refresh(*ui_master);};
	use_ks_curses();
	io_cycle(*ui_master);
}

#scope_file
left_box := UI_Button.{
	zone_default = .{
		corner = .{0, 0},
		size = .{20, 10}
	},
	on_click = () {
		if select_list.selected != -1 {
			fruit := select_list.options[select_list.selected];
			array_add(*app_state.log_lines, sprint("(%) %", app_state.counter, fruit));
			app_state.counter += 1;
			middle_box.lines = app_state.log_lines;
		}
	},
	text = "click me!"
};
middle_box := UI_Text_Block.{
	zone_default = .{
		corner = .{20, 0},
		size = .{10, 10}
	},
	scale_mode = anchor_t
};
select_list := UI_Select_List.{
	zone_default = .{
		corner = .{0, 10},
		size = .{20, 10}
	},
	scale_mode = anchor_lt,
	options = .["banana", "apple", "apricot"]
};

right_box := UI_Button.{
	zone_default = .{
		corner = .{30, 0},
		size = .{20, 10}
	},
	scale_mode = anchor_rt,
	on_click = reset_log,
	text = "me too!"
};

//TODO "sure you want to exit?" & popups/multiple screens at all
ui_master := UI_Master.{
	size_min = .{40, 20},
	size_default = .{50, 30}
};

app_state : struct {
	log_lines : [..]string;
	counter := 0;
}
reset_log :: () {
	for app_state.log_lines free(it);
	array_reset(*(app_state.log_lines));
	middle_box.lines = app_state.log_lines;
}