Event :: struct {
	type : enum u8 {
		NONE	:: 0;
		KEY		:: 1;
		WINCH	:: 2;
		TICK	:: 3;
		INIT	:: 4;
		USER	:: 5;
	};
	union {
		key : Key;
		data : *void;
	}
}

__event_handler : struct {
	proc := (e : Event, __data : *void) { 
		assert(__data != null);
		if e.type == {
			case .NONE;
			ks_write("empty_event!\n\r");
			case .KEY;
			ks_write(tprint("key = %\n\r", e.key));
			case .WINCH;
			ks_write(tprint("winch, size = %\n\r", terminal_state.size));
			case .TICK;
			ks_write(tprint("tick\n\r"));
		}
		if e.type == .KEY && e.key == .ESCAPE {
			<<cast(*bool)__data = true; // stop_main = true
		}
	};
	data : *void;
}

use_events :: (tick_duration_ms :s32= 1000, $use_clock := true, init_event := true) #expand {
	init_mutexes();
	#if use_clock clock_thread := start_clock_cycle(tick_duration_ms);
	input_thread := start_input_cycle();
	winlooker_thread := start_winlooker_cycle();
	set_handler();
	if init_event push_event(.{type = .INIT});
	`defer {
		restore_handler();
		stop_winlooker_cycle(winlooker_thread);
		stop_input_cycle(input_thread);
		#if use_clock stop_clock_cycle(clock_thread);
		deinit_mutexes();
		reset_globals();
	}
}
wait_and_process_events :: () -> bool {
	wait_for(*event_wait_sem);
	lock(*event_queue_mtx); defer unlock(*event_queue_mtx);
	processed := false;
	while 1 {
		e, ok := pop(*event_queue);
		if !ok break;
		processed = true;
		assert(e.type != .NONE);
		__event_handler.proc(e, __event_handler.data);
	}
	return processed;
}
pop_events :: () -> bool {
}
push_event :: (e : Event) {
	// notice := false;
	lock(*event_queue_mtx);
	// notice = (event_queue.count == 0);
	push(*event_queue, e);
	unlock(*event_queue_mtx);
	signal(*event_wait_sem);

	// lock(*event_wait_cond_mtx);
	// pthread_cond_signal(*event_wait_cond);
	// unlock(*event_wait_cond_mtx);
}

restart_clock_cycle :: () {
	assert(clock_state != .DISABLED);

	lock(*mtx_clock_state);
		if clock_state != .STOP {
			clock_state = .RESTART;
		}
		signal(*sem_clock_breaker);
	unlock(*mtx_clock_state);
}

#scope_file
// SIGWINCH --sigaction--> handler --pipe--> winlooker --push_event--|--> event_queue --pop_events--> master thread
// 							     stdin --read--> input --push_event--|
//												 clock --push_event--|


// event_queue
event_queue_mtx : Mutex;
event_queue : Queue(Event);

event_wait_sem : Semaphore;

// handler
handler :: (sig : s32) #c_call {
	new_context : Context;
	push_context new_context {
		if sig == SIGWINCH {
			msg : u8 = 42;
			write(fd_winch[1], *msg, 1);
		} else {
			print("signal = %\n\r", sig);
		}		
	}
}
set_handler :: () {
	sa : sigaction_t;
	sa.sa_handler = handler;
	sigemptyset(*(sa.sa_mask));
	sa.sa_flags = SA_RESTART;
	sigaction(SIGWINCH, *sa, null);
}
restore_handler :: () {
	sa : sigaction_t;
	sa.sa_handler = SIG_DFL;
	sigaction(SIGWINCH, null, *sa);
}

// winlooker
fd_winch : [2]s32;
stop_winlooker := false;
winlooker_cycle :: (thread : *Thread) -> s64 {



	while !stop_winlooker {
		msg : u8;
		r := read(fd_winch[0], *msg, 1);
		if stop_winlooker break;
		// assert(msg == 42); //TODO r != 1 case
		update_terminal_size();
		push_event(.{type = .WINCH});
	}
	// exit(2);
	close(fd_winch[0]);
	return 0;
}
start_winlooker_cycle :: () -> *Thread #expand {
	pipe(*fd_winch);
	winlooker_thread : Thread;
	thread_init(*winlooker_thread, winlooker_cycle);
	print("winlooker = %\n\r", formatInt(winlooker_thread.thread_handle, base = 16));
	thread_start(*winlooker_thread);
	return *winlooker_thread;
}
stop_winlooker_cycle :: (winlooker_thread : *Thread) {
	stop_winlooker = true;	
	// exit(1);
	close(fd_winch[1]);
	// exit(1);
	pthread_cancel(winlooker_thread.thread_handle);
	thread_deinit(winlooker_thread);
	// exit(1);
}

// input
stop_input := false;
input_cycle :: (thread : *Thread) -> s64 {
	tcflush(STDIN_FILENO, TCIFLUSH);
	while !stop_input {
		key := ks_getch();
		if stop_input break;
		push_event(.{type = .KEY, key = key});
	}
	return 0;
}
start_input_cycle :: () -> *Thread #expand {
	input_thread : Thread;
	thread_init(*input_thread, input_cycle);
	print("input = %\n\r", formatInt(input_thread.thread_handle, base = 16));
	thread_start(*input_thread);
	return *input_thread;
}
stop_input_cycle :: (input_thread : *Thread) {
	stop_input = true;
	pthread_cancel(input_thread.thread_handle);
	thread_deinit(input_thread);
}

// clock
clock_state : enum u8 {
	NORMAL	:: 0;
	STOP	:: 1;
	RESTART :: 2;
	DISABLED:: 3;
} = .DISABLED;
sem_clock_breaker : Semaphore;
mtx_clock_state : Mutex;

clock_cycle :: (thread : *Thread) -> s64 {
	tick_duration_ms := <<cast(*s32)thread.data;

	while clock_state != .STOP {
		lock(*mtx_clock_state); 
			destroy(*sem_clock_breaker);
			init(*sem_clock_breaker);
			clock_state = .NORMAL;
		unlock(*mtx_clock_state);

		while 1 {
			r := wait_for(*sem_clock_breaker, tick_duration_ms);

			lock(*mtx_clock_state); defer unlock(*mtx_clock_state);
			if clock_state != .NORMAL {
				assert(r == .SUCCESS);
				break;
			} else {
				push_event(.{type = .TICK});
			}
		}
	}
	return 0;
}
start_clock_cycle :: (tick_duration_ms : s32) -> *Thread #expand {
	clock_thread : Thread;
	init(*sem_clock_breaker);
	init(*mtx_clock_state);
	clock_state = .NORMAL;

	thread_init(*clock_thread, clock_cycle);
	
	tick_duration_ms_ptr := New(s32);
	<<tick_duration_ms_ptr = tick_duration_ms; 

	clock_thread.data = tick_duration_ms_ptr;
	print("clock = %\n\r", formatInt(clock_thread.thread_handle, base = 16));
	thread_start(*clock_thread);
	return *clock_thread;
}
stop_clock_cycle :: (clock_thread : *Thread) {
	lock(*mtx_clock_state);
		clock_state = .STOP;
		signal(*sem_clock_breaker);
	unlock(*mtx_clock_state);

	thread_deinit(clock_thread);
	free(clock_thread.data);
	clock_state = .DISABLED;
	destroy(*sem_clock_breaker);
	destroy(*mtx_clock_state);
}

// utils
reset_globals :: () {
	stop_input = false;
	clock_state = .NORMAL;
	// stop_clock = false;
	stop_winlooker = false;
	fd_winch = .[0, 0];
	deinit(*event_queue);
}
init_mutexes :: () {
	init(*event_wait_sem);
	init(*event_queue_mtx);
}
deinit_mutexes :: () {
	destroy(*event_queue_mtx);
	destroy(*event_wait_sem);
}


TCIFLUSH :: 0;

libc :: #system_library "libc";
tcflush :: (fd : s32, queue_selector : s32) -> s32 #foreign libc;

#import "Thread";