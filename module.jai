ENABLE_SIGINT :: false;
ENABLE_SIGTERM :: true;
ENABLE_SIGKILL :: true;

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
#load "window.jai";
#load "style.jai";

#load "ui/master.jai";
#load "ui/text_block.jai";
#load "ui/line_input.jai";
#load "ui/button.jai";
#load "ui/select_list.jai";
#load "ui/anchors.jai";
