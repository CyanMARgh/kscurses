demo_03 :: () {
	main_group := UI_Group.{ box_type = .NO_BORDER };
		buttons_group : UI_Group;
			buttons : [3]UI_Button;
		bars_group : UI_Group;
			bars : [6]UI_Progress_Bar = .[
				.{description = "velocity: x", description_pos = .TOP_LEFT},
				.{description = "velocity: y", description_pos = .TOP_CENTER},
				.{description = "velocity: z", description_pos = .TOP_RIGHT},
				.{description = "acceleration: x", description_pos = .BOTTOM_LEFT},
				.{description = "acceleration: y", description_pos = .BOTTOM_CENTER},
				.{description = "acceleration: z", description_pos = .BOTTOM_RIGHT}
			];
	set_sub_elements(*main_group, 
		.{*buttons_group, .{60, 10, 0, 0}},
		.{*bars_group,    .{60, 20, 0, 10}}
	);
	set_sub_elements(*bars_group,
		.{*bars[0], .{58, 3, 0,  0}},
		.{*bars[1], .{58, 3, 0,  3}},
		.{*bars[2], .{58, 3, 0,  6}},
		.{*bars[3], .{58, 3, 0,  9}},
		.{*bars[4], .{58, 3, 0, 12}},
		.{*bars[5], .{58, 3, 0, 15}}
	);


	values := array_copy(float.[.813, .123, .451, .234, .051, .567]);
	defer array_free(values);
	for i : 0..5 set_value_ptr(*bars[i], *values[i]);

	struct_lambda(#code { __ui_master.extra_handle; values; (e : Event) -> (); {
		if e.type == .TICK {
			for * <<_values {
				<<it *= .95;
			}
		}
	}});

	set_main_scene(.{*main_group, *buttons_group});

	use_ks_curses();
	run_multithread_ui();
}