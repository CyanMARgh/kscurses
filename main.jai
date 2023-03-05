DEBUG :: false;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

#load "demo_0.jai";
#load "demo_1.jai";

main :: () {
	demo_0();
}