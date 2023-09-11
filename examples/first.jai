DEBUG :: true;
IMPORT_EXTRA_PATH :: "../..";

#import "Basic";
#import "Compiler";
#import "Process";

#run {
	set_build_options_dc(.{do_output=false});
	build();
}

#if OS == .LINUX {
	EXECUTABLE_SUFFIX :: ".elf";
} else #if OS == .WINDOWS {
	EXECUTABLE_SUFFIX :: "";
} else {
	#run assert(false, "invalid OS");
}

build :: () {
	w := compiler_create_workspace();
	if !w {
		print("Workspace createion failed!\n");
		return;
	}
	target_options := get_build_options(w);
	
	executable_name := sprint("main%1", 
		EXECUTABLE_SUFFIX
	); defer free(executable_name);
	{
		using target_options;
		text_output_flags = 0;

		#if DEBUG {
		} else {
			llvm_options.bitcode_optimization_setting = .O3;
			stack_trace = false;
			array_bounds_check = .OFF;
			cast_bounds_check = .OFF;
			math_bounds_check = .OFF;
			null_pointer_check = .OFF;
			dead_code_elimination = .ALL;
			backtrace_on_crash = .OFF;
		}
		import_path = .[import_path[0], IMPORT_EXTRA_PATH];

		output_executable_name = executable_name;
	}
	set_build_options(target_options, w);
	compiler_begin_intercept(w);
	add_build_file(tprint("%1/main.jai", #filepath), w);
	add_build_string(tprint("DEBUG :: %;\n", DEBUG), w);

	while 1 {
		message := compiler_wait_for_message();
		if message.kind == {
			case .COMPLETE;
			break;
		}
	}
	compiler_end_intercept(w);
}