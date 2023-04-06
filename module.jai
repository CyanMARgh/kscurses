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

// TODO test 2 input windows
// TODO maybe change logger in context
// TODO make adding new ui types posible
// TODO multiple scenes & subwindows/ui groups & popus support
// TODO add meaningfull assertion text

// TODO add windows(os) support xd
