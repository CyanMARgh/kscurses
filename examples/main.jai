#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import "kscurses";
#import "Extra_Containers";

#load "demo_00.jai";
#load "demo_01.jai";
#load "demo_02.jai";
#load "demo_03.jai";
#load "demo_04.jai";
#load "demo_05.jai";
#load "demo_06.jai";
#load "demo_07.jai";
#load "demo_08.jai";
// // ?
#load "demo_10.jai";
#load "demo_11.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	demo_00();
	// demo_01();
	demo_02();
	demo_03();
	demo_04();
	demo_05();
	demo_06();
	demo_07();
	demo_08();

	demo_10();
	demo_11();
}
