DEBUG :: true;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai"(TICK_DURATION_MS = 40);

#load "demo_0.jai";
#load "demo_1.jai";
#load "demo_2.jai";
// 演示 3 中沒有發生任何事情
#load "demo_4.jai";
#load "demo_5.jai";
#load "demo_6.jai";
#load "demo_7.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	demo_0();
	demo_1();
	demo_2();
	
	demo_4();
	demo_5();
	demo_6();
	demo_7();
}