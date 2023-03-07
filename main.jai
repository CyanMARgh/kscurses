DEBUG :: false;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

#load "demo_0.jai";
#load "demo_1.jai";
#load "demo_2.jai";
#load "demo_3.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	// demo_0();
	// demo_1();
	// demo_2();
	demo_3();
}