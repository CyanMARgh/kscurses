#module_parameters(
	ENABLE_SIGINT		:= true,
	ENABLE_SIGQUIT		:= true,
	TICK_DURATION_MS	:= 1000,
	ENABLE_UI_BELL		:= true
);


#import "Basic"();
#import "POSIX";
#import "Process";
#import "String";

#assert OS == .LINUX;

#load "queue.jai";
#load "io.jai";
// #load "resize.jai";
#load "init.jai";
#load "ivec.jai";
#load "modes.jai";
#load "print.jai";
#load "utils.jai";
#load "canvas.jai";
#load "events.jai";

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

// TODO:

// EDIT README 
//	- features
//  - demos description
// make better how_to

// (maybe) change logger in context
// add meaningfull assertion text
// UI_Scene <- UI_Popup
// painter/handler vtables
// make adding new ui types posible
// solve the problem with multithreading and canvas.
// autogrow in line_input
// detection of the element on which rendering breaks
// extra debug lines on top
// scalable group / group view
// 16 char support in box
// make u8/u32 modes in text_buf & line_input
// add block_input
// add windows(os) support xd
// (maybe) unset_active_recursive without arguments

// add module parameters 
