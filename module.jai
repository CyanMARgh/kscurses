#module_parameters(
	ENABLE_SIGINT		:= true,
	ENABLE_SIGQUIT		:= true,
	TICK_DURATION_MS	:= 1000,
	ENABLE_UI_BELL		:= true,
	ENABLE_UI_BLINKING	:= true
);


#import "Basic"();
#import "POSIX";
#import "Process";
#import "String";

#assert OS == .LINUX;

#load "io.jai";
#load "init.jai";
#load "events.jai";

// #load "resize.jai";
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

#load "lambdas.jai";
#load "queue.jai";

// TODO:

// ks_draw_canvas (+) only_diff := true
// restart_clock && multiple clocks

// make better how_to
// add meaningfull assertion text
// UI_Scene <- UI_Popup
// painter/handler vtables & make adding new ui types posible
// autogrow in line_input
// detection of the element on which rendering breaks
// extra debug lines on top
// scalable group / group view
// + grid / group (maybe)
// 16 char support in box
// make u8/u32 modes in text_buf & line_input
// add block_input
// (maybe) unset_active_recursive without arguments

// add windows(os) support xd
