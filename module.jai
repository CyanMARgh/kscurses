#module_parameters(
	ENABLE_SIGINT		:= true,
	ENABLE_SIGQUIT		:= true,
	TICK_DURATION_MS	:= 1000,
	ENABLE_UI_BELL		:= true,
	ENABLE_UI_BLINKING	:= true
);

#if OS == .LINUX {
	#import "POSIX";
}

#import "Basic"();
#import "Process";
#import "String";

#load "io.jai";
#load "init.jai";
#load "events.jai";

#load "ivec.jai";
#load "modes.jai";
#load "print.jai";
#load "utils.jai";
#load "canvas.jai";

#load "ui/style.jai";
#load "ui/element.jai";
#load "ui/master.jai";
#load "ui/links.jai";

#load "ui/button.jai";
#load "ui/group.jai";
#load "ui/text_buf.jai";
#load "ui/select_list.jai";
#load "ui/parent.jai";
#load "ui/scene_manager.jai";
#load "ui/popup_manager.jai";
#load "ui/line_input.jai";
#load "ui/table.jai";
#load "ui/scalable_group.jai";
#load "ui/progress_bar.jai";

#load "lambdas.jai";
#load "queue.jai";

// TODO:
// remake canvas:
//		-force full refresh only after resize / init
// 		maybe_resize()
//		fill_by_proc()
//		clear()


//		in resize & fill: check if size same
// 		add c_print_ascii_line, c_print_ascii_line_bounded

// restart_clock && multiple clocks

// in set_main_scene check if root is predecessor of active element
// stop_clock -> clock_state

// module overlap check / set minimum size of terminal

// make generic_vec2/3
// make better how_to
// add meaningfull assertion text
// UI_Scene <- UI_Popup
// autogrow in line_input
// detection of the element on which rendering breaks
// extra debug lines on top
// group view
// + grid / group (maybe)
// make text u8/u32 modes in text_buf, line_input & other
// add block_input
// (maybe) unset_active_recursive without arguments
// plotter
// tree/directory view
// push graphics mode

// add windows(os) support xd
