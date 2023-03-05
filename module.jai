ENABLE_SIGINT :: true;
ENABLE_SIGTERM :: true;
ENABLE_SIGKILL :: true;
DOUBLE_ESCAPE_EXIT :: false;
ENABLE_ARROWS :: true;

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
#load "window.jai";
