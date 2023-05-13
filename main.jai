DEBUG :: true;
#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import,file "module.jai";

#load "demos/demo_0.jai";
#load "demos/demo_1.jai";
#load "demos/demo_2.jai";
// 演示 3 中沒有發生任何事情
#load "demos/demo_4.jai";
#load "demos/demo_5.jai";
#load "demos/demo_6.jai";
#load "demos/demo_7.jai";
#load "demos/demo_8.jai";

main :: () {
	#if DEBUG defer report_memory_leaks();
	demo_0();
	demo_1();
	demo_2();
	
	demo_4();
	demo_5();
	demo_6();
	demo_7();
	demo_8();
}
