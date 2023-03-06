DEBUG :: false;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

#load "demo_0.jai";
#load "demo_1.jai";
#load "demo_2.jai";

main :: () {
	demo_0();
}