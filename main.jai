DEBUG :: true;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

#load "demos/demo_00.jai";
#load "demos/demo_01.jai";
#load "demos/demo_02.jai";
#load "demos/demo_03.jai";
#load "demos/demo_04.jai";
#load "demos/demo_05.jai";
#load "demos/demo_06.jai";
#load "demos/demo_07.jai";
#load "demos/demo_08.jai";
// ?
#load "demos/demo_10.jai";
#load "demos/demo_11.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	// demo_00();
	demo_01();
	// demo_02();
	// demo_03();
	// demo_04();
	// demo_05();
	// demo_06();
	// demo_07();
	// demo_08();

	// demo_10();
	// demo_11();
}
