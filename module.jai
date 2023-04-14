ENABLE_SIGINT	:: true;
ENABLE_SIGTERM	:: true;
ENABLE_SIGKILL	:: true;
ENABLE_UI_BELL	:: true;
KEEP_CLIPBOARD	:: true; // true now for debug purposes

#import "Basic"();
#import "POSIX";
#import "Process";
#import "String";

#assert OS == .LINUX;

#load "io.jai";
#load "resize.jai";
#load "init.jai";
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

// TODO:

// restore old demos

// (maybe) change logger in context
// add meaningfull assertion text
// UI_Scene <- UI_Popup
// painter/handler vtables
// make adding new ui types posible
// solve the problem with multithreading and canvas.
// replace []bool modes with flags
// autogrow in line_input
// detection of the element on which rendering breaks
// extra debug lines on top
// extra_handler :: (key : Key, *data)
// scalable group / group view
// 16 char support in box
// make u8/u32 modes in text_buf line_input
// add block_input
// add windows(os) support xd
// (maybe) unset_active_recursive without arguments

// add module parameters 
// make better how_to
