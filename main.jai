DEBUG :: true;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

// #load "demo_0.jai";
#load "demo_1.jai";
// #load "demo_2.jai";
// #load "demo_3.jai";
#load "demo_4.jai";
#load "demo_5.jai";
#load "demo_6.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	// demo_2();
	// demo_0();
	// demo_1();
	// demo_3();
	// demo_4();
	// demo_5();
	demo_6();
}