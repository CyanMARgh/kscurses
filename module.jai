ENABLE_SIGINT :: true;
ENABLE_SIGTERM :: true;
ENABLE_SIGKILL :: true;
ENABLE_ARROWS :: true;
ESCAPE_DELAY_MS :: 10;

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
