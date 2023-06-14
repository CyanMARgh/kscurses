#scope_export

/*

  Below is the new Thread_Group stuff.

  This is a way of launching a bunch of threads to asynchronously respond to requests.

  First you call init() on a Thread_Group, indicating how many threads you want.
  It's a good idea to have the number of threads be intelligently chosen based on
  how many CPU cores you have, and how many are likely to be in use at the time
  this code is running. You also give init() a callback procedure that will be called
  when a particular thread wants to do some work.

  You can then set some parameters manually, like whether logging should be turned on,
  the name of the Thread_Group (which you'll see in log messages), and the 'data' pointer
  which is just a general user-specified data slot, to give your callback additional
  information.

  Once you call start() on the Thread_Group, the threads will start running.
  When you want the threads to stop running, you need to call shutdown(), which will
  wait until all the threads exit. You probably need to do this before your program exits;
  it is a bad thing to have threads running while you clean up various global state
  that they may be trying to use.

  When you want to give the Thread_Group work to do, you call add_work, giving it
  a *void that represents the work you want to do. (This is some piece of memory,
  the meaning of which is determined entirely by you -- it just gets passed to your callback --
  and the lifetime of which is controlled by you, but must be longer than the period
  during which the thread will be doing the work!) At some point, a thread will grab
  this work and execute it. When the work is done, your *void will be added to a
  "work completed" queue. Call get_completed_work() occasionally to see what has
  been completed, and to do whatever you want to do in response (maybe you want to
  do some further main-thread processing on that piece of work; maybe you want to free
  the memory.)


  This Thread_Group is architected a little differently than many people may expect.
  For example, it is not a "job system" in the way that came into vogue a few years ago
  in the video game world.

  Here, each thread is calling the same function, in order to remove some barriers to
  good performance. When you have a bunch of jobs grabbing random pieces of work and
  executing them, you can't expect any relevant data or instructions to be in cache
  when the work starts (because the previous job ran different code and operated on
  totally different data on that thread).

  Also, here we avoid the pattern of using a single queue to hold the input and output.
  It's a common pattern, taught in school and on the internet, to have a single queue,
  and a semaphore, and you just put work into that queue, increment the semaphore, and
  an arbitrary one of the threads pulls the work off the queue. This is actually
  a performance disaster on modern-day CPUs, so you don't want to do it that way.
  Performance is bad because of the CPU's cache-coherency mechanisms. When all the
  threads are hammering on the same couple of cache lines, to grab input and
  write output, they spend a great deal of time waiting on each other.
  For example, say you want one of the threads to pop a piece of work off a linked list,
  writing back the new head of the list so that nobody else grabs the same work.
  The way this is implemented on the CPU, that core needs to lock the cache line
  containing the head of the linked list. It needs to talk to all other cores
  to make sure none of them have any writes pending on that cache line, and to get
  all those cores to flush their copy of the cache line, because it's no longer valid.
  After this synchronization is done, the core can then write the new head of the list,
  that can write back to main memory, and other cores can read that memory anew
  (which will of course take a long time to get). After all this is done, maybe
  another core can now try to grab a piece of work, starting this whole boondoggle
  over again.

  This is bad enough when you have just a few threads doing it, but as consumer-level computers
  get more and more cores, you can imagine an increasing number of cores fighting over
  the same memory location -- like, 64 of them.

  So you can write code that looks sleek and simple and parallel, but in reality
  a large amount of tremendously inefficient synchronization is happening behind the scenes.
  Since the whole point of writing parallel code is to avoid synchronization, that is
  pretty bad.

  (If you are running on a system that provides an optional weak memory model,
  this description may not exactly apply, but if you are doing that successfully, you know
  what you are doing and do not need this documentation).

  To mitigate this situation, we have separate input and output queues for each thread.
  When we issue a new piece of work, we give it to a particular thread. Thus only two
  cores are concerned with writing to any particular cache line.

  Because we assign work to specific threads, we will tend end up in a situation where some threads
  complete, but other threads still have work piled up, which means a decreasing number of
  threads are active over time. To handle this case, we have implemented work stealing
  based on "The Power of Two Random Choices":
  https://people.cs.umass.edu/~ramesh/Site/PUBLICATIONS_files/MRS01.pdf
  Work-stealing is currently disabled by default since it is new and untested, but it will
  default to true eventually once it's tested.
  -jblow, 21 June 2021.

*/


Thread_Group_Proc :: #type (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status;

// Thread_Continue_Status is returned by your worker procedure.
// If you return STOP, this is probably due to a resource shortage of some sort,
// so this thread will stop running. You usually want to return CONTINUE.
Thread_Continue_Status :: enum {
    STOP     :: 0;
    CONTINUE :: 1;
}

Thread_Group :: struct {

    //
    // User-configurable data members:
    //

    data: *void;               // You can set this to whatever value you want, like 'data' on Thread.
    proc: Thread_Group_Proc;   // This is set in init(), but you can change it before calling start() if you want. You set this to whatever procedure you want called when a thread is performing work.
    name: string;              // You can set this to whatever you want; it gets used in log messages.
    logging := true;           // Disable logging by setting this to false (you probably want to do that to avoid spam, once things are working).

    time_proc: () -> float64;  // For logging purposes, this code wants to report the time. You can set this procedure to control how Thread_Group
                               // gets the time. If this is null, we use Basic.get_time() instead.


    //
    // Implementation details below. Do not modify these!
    //

    allocator:      Allocator;   // The allocator is saved on init, as happens with many data structures. This allocator need not be threadsafe,
                                 // since it is only used on the thread that is calling the Thread_Group functions. The worker threads do not allocate.

    worker_info: [] Worker_Info;
    worker_info_data_to_free: *void;

    next_worker_index: s32;

    // To avoid false sharing between CPU cores, we pad Worker_Info to the cache line size.
    // Hopefully the user of this module passed a good line size as a module parameter.
    // If you don't know the cache line size of your target machine, it's not too bad if
    // you conservatively pick a number that is a little too big. But picking a number
    // that is too small is not a good idea.
    Worker_Info :: struct {
        using info: Unpadded_Worker_Info;

        DESIRED_SIZE :: #run Basic.align_forward(size_of(type_of(info)), CACHE_LINE_SIZE);
      #place info;
        padding: [DESIRED_SIZE] u8 = ---;
        work_steal_indices: [] s32;
    }

    Unpadded_Worker_Info :: struct { // Used as input for Worker_Info.
        thread:       Thread;
        available:    Work_List;
        completed:    Work_List;

        group:        *Thread_Group;
        worker_index: s32;
    }

    // Each thread has two Work_Lists: 'available', for input, and 'completed', for output.
    Work_List :: struct {
        semaphore: Semaphore;
        mutex:     Mutex;
        first:     *Work_Entry;
        last:      *Work_Entry;

        count:    s32;
    }

    // The Thread_Group creates a Work_Entry for each work pointer passed in by the user.
    // The Work_Entry stores extra random useful data.
    Work_Entry :: struct {
        next:            *Work_Entry;
        work:            *void;
        thread_index:    Thread_Index;  // This is Thread.index for the thread that handled this work.
        logging_name:    string;

        issue_time:      float64;
        work_list_index: s32;
    }

    // should_exit gets set during shutdown, to indicate that all
    // threads should stop looping. You probably should not set this yourself.
    // Call shutdown(*thread_group) instead.
    initted     := false;
    started     := false;
    should_exit := false;
}

Work_List  :: Thread_Group.Work_List;
Work_Entry :: Thread_Group.Work_Entry;


// init() initializes your Thread_Group. After calling init() you may still wish to
// assign a few data members to customize Thread_Group; see the struct declaration of
// Thread_Group above for more info.
init :: (using group: *Thread_Group, num_threads: s32, group_proc: Thread_Group_Proc, enable_work_stealing := false) {
    // enable_work_stealing will default to true eventually. See the note at the start of this file.
    Basic.remember_allocators(group);

    worker_info, worker_info_data_to_free = Basic.NewArray(num_threads, Worker_Info, true, group.allocator, alignment=CACHE_LINE_SIZE);  // alignment = ... allocates extra memory so we can bump.

    // Bump worker_info.data so that it is cache-line aligned.
    assert((cast(u64) worker_info.data) % cast(u64) CACHE_LINE_SIZE == 0);

    group.proc = group_proc;

    for * info: worker_info {
        thread_init(*info.thread, thread_group_run);
        info.thread.worker_info = info;

        init_work_list(*info.available);
        init_work_list(*info.completed);

        info.group        = group;
        info.worker_index = cast(s32) it_index;

        if enable_work_stealing && (num_threads > 1) {
            // Make an array that contains all worker indices except for ours.
            // This gets shuffled for work stealing. Why? Because we want to
            // search through 2 threads for work, but if they are mostly empty,
            // we might have to scan through the whole array anyway. Maybe this
            // is not the best way to do it.

            indices := Basic.NewArray(num_threads-1, s32, false, group.allocator);
            cursor := 0;
            for i: 0..num_threads-1 {
                if i == it_index continue;

                indices[cursor] = i;
                cursor += 1;
            }

            info.work_steal_indices = indices;
        }
    }

    group.initted = true;
}

// When you want the threads to start running, call start().
start :: (group: *Thread_Group) {
    for * group.worker_info  thread_start(*it.thread);

    group.started = true;
}

// shutdown() tells all threads to stop and waits for up to timeout_milliseconds for them to finish. (Pass -1 to wait indefinitely.)
// It returns true if all threads finished in time and could be deallocated. After that, the user_data pointer will no longer be valid for
// any Thread (the memory is freed!), so if you want to use that to deinit your own user data, do that first!
// If you pass a timeout_milliseconds other than -1, shutdown may return false if threads did not finish in time.
// In that case nothing was freed and you need to call shutdown again until it returns true to free all resources.
shutdown :: (using group: *Thread_Group, timeout_milliseconds: s32 = -1) -> bool {
    assert(initted);  // The user should not call shutdown if they did not init.

    should_exit = true;

    all_done := true;
    if started {
        // Signal all semaphores so that the threads wake up. They should see
        // that should_exit is set and break immediately. Keep in mind, though,
        // that threads could be processing work and thus be unavailable
        // for an arbitrarily long time.
        for * worker_info  signal(*it.available.semaphore);

        start: Basic.Apollo_Time;
        if timeout_milliseconds > 0 {
            start = Basic.current_time_consensus();
        }
        remaining_timeout_ms := timeout_milliseconds;
        for * worker_info {
            if remaining_timeout_ms > 0 {
                elapsed := Basic.to_milliseconds(Basic.current_time_consensus() - start);
                remaining_timeout_ms = cast(s32) (timeout_milliseconds - elapsed);
                if remaining_timeout_ms < 0 remaining_timeout_ms = 0;
            }

            is_done := thread_is_done(*it.thread, remaining_timeout_ms);
            if !is_done all_done = false;
        }
    }

    if !all_done return false;

    // If all threads have exited, we are ready to deallocate them.
    for * worker_info {
        thread_deinit(*it.thread);
        deinit_work_list(*it.available);
        deinit_work_list(*it.completed);
        Basic.free(it.work_steal_indices.data);
    }

    Basic.free(worker_info_data_to_free);
    return true;
}

// Call add_work() to add a unit of work, which will be given to one of the threads.
add_work :: (group: *Thread_Group, work: *void, logging_name := "") {
    assert(group.worker_info.count >= 0);

    // Make a Work_Entry, a linked list node that lets us queue and unqueue.
    entry := Basic.New(Thread_Group.Work_Entry, true, group.allocator);

    entry.work         = work;
    entry.logging_name = logging_name;
    entry.issue_time   = get_time(group);   // @Threadsafety: get_time() init is not threadsafe! @Incomplete, fix that!

    // Choose which thread will run this work. Right now we do a dead simple cycle
    // through the worker array, adding 1 to the index each time. There may be
    // better things to do.
    thread_index := group.next_worker_index;
    group.next_worker_index += 1;
    if group.next_worker_index >= group.worker_info.count  group.next_worker_index = 0;

    entry.work_list_index = thread_index;

    // Add this node to the linked list of available work for that thread.
    list := *group.worker_info[thread_index].available;
    add_work(list, entry);

    // The extra spaces after "added" are intentional, to make more-readable alignment with other log messages if they happen to occur in succession.
    if group.logging  Basic.log("'%' added     work '%' to the available list at time %.\n", group.name, entry.logging_name, entry.issue_time);
}

// Call get_completed_work() regularly to see which of your work units are done.
get_completed_work :: (group: *Thread_Group) -> [] *void {  // The result array is allocated via temporary storage.
    results: [..] *void;
    results.allocator = Basic.__temporary_allocator;

    count:     s32;

    // We iterate over every worker thread to see if anything has completed.
    // Note that if this Thread_Group is idle most of the time, and you call
    // get_completed_work once per frame, most of the time this loop will
    // just be waste. Hopefully it's not very much waste compared to everything else
    // your program is doing, but in the future we may add an early-out:
    // if all work was completed before, and we never added new work, obviously
    // we don't need to do anything, as there can't be any new work.
    for * info: group.worker_info {
        list := *info.completed;

        count:     s32;         // We get the values of 'count' and 'completed' inside the mutex,
        completed: *Work_Entry; // but then release the mutex before working with them, to minimize
                                // the amount of time we are holding the lock.
        {
            // Lock this thread's mutex to get the information we want.
            lock(*list.mutex);
            count      = list.count;
            completed  = list.first;

            // We are going to output the entire list that has accumulated so far,
            // so reset the list to an empty state.
            if list.first {  // Avoid writes if they are not necessary.
                list.first = null;
                list.last  = null;
                list.count = 0;
            }

            unlock(*list.mutex);
        }

        if !completed continue;

        // Reserve the output array. Probably doesn't help much. Note that
        // we are maybe adding small numbers of results over a larger number
        // of cores. Really if we want to be efficient here, we can build
        // a larger linked list out of the mini-lists we gather, and accumulate
        // the counts, then do the reserve all in one batch when we are done
        // looking at the threads. For simplicity this has not yet been done,
        // but it may not be much more complicated, actually.
        Basic.array_reserve(*results, results.count + count);

        old_count := results.count;

        // Put the link list nodes into the output array, and then free the nodes.
        // This means the user doesn't have to care what our list node looks like,
        // and just gets to think about the work units he added in the first place.
        while completed {
            array_add(*results, completed.work);
            next := completed.next;

            if group.logging {
                now := get_time(group);
                elapsed := now - completed.issue_time;
                Basic.log("'%' completed work '%' from thread % at time % (elapsed: %).\n", group.name, completed.logging_name, completed.thread_index, now, elapsed);
            }

            Basic.free(completed, group.allocator);  // @Speed: Could maintain a list of unused Work_Entries instead of alloc and freeing them. Not sure if it's worth the complexity.
            completed = next;
        }

        assert(results.count == old_count + count);
    }

    if results.count && group.logging {
        plural := ifx results.count > 1 then "s" else "";
        Basic.log("'%' is returning % result% from get_completed_work().\n", group.name, results.count, plural);
    }

    return results;
}

#scope_file

init_work_list :: (using list: *Work_List) {
    init(*semaphore);
    init(*mutex);
}

deinit_work_list :: (using list: *Work_List) {
    destroy(*semaphore);
    destroy(*mutex);
}

add_work :: (using list: *Work_List, entry: *Work_Entry) {
    // Add entry onto the linked list.

    lock(*mutex);

    if last {
        // The list has nodes in it. Put this entry onto the end so that we are FIFO.
        last.next = entry;
        last      = entry;
    } else {
        // The list is empty. This entry is now the entire list.
        first     = entry;
        last      = entry;
    }

    list.count += 1;

    unlock(*mutex);

    signal(*semaphore);
}

get_work :: (using list: *Work_List) -> *Work_Entry {
    // When a thread wants to get a new unit of work, it calls this.
    // To get here, it must have passed its semaphore, thus there absolutely
    // must be work available, or else the program is incorrect.

    lock(*mutex);
    defer unlock(*mutex);

    if !first return null;  // If someone else stole work, there may be none available.

    // Grab the first node as our result.
    result := first;

    // Update the head of the list to be the next item.
    first   = result.next;

    // If the new 'first' pointer is null, the list has become empty, so set 'last' to null also.
    if !first  last = null;

    list.count -= 1;

    return result;
}

thread_group_run :: (thread: *Thread) -> s64 {
    // This is the main loop that a particular thread runs.
    // It waits on its semaphore, looking for new work on its 'available' list.
    // When it finds work, it calls the thread group procedure with the work,
    // then puts the work into its 'completed' list.

    info := thread.worker_info;
    group := info.group;

    entry: *Work_Entry;
    while !group.should_exit {
        if !entry {
            wait_for(*info.available.semaphore);
            if group.should_exit  break;  // Don't do the proc, since that might take time.

            // Remove work from the list. There might be none if someone stole.
            entry = get_work(*info.available);
        }

        if entry {
            // The thread index gets used in logging, so assign it here.
            entry.thread_index = thread.index;
            entry.next         = null;

            // The extra space after "assigned" is intentional, to make more-readable alignment with other log messages if they happen to occur in succession.
            if group.logging  Basic.log("'%' assigned  work '%'   to thread % at time %.\n", group.name, entry.logging_name, thread.index, get_time(group));

            should_continue := Thread_Continue_Status.CONTINUE;
            if group.proc {
                should_continue = group.proc(group, thread, entry.work);
            }

            // The work is done. Add the entry to the completed list.
            // It will be removed from the completed list when the user
            // calls get_completed_work().
            add_work(*info.completed, entry);

            if should_continue == .STOP  break;
        }

        if info.work_steal_indices.count {
            if group.should_exit  break;  // Check before dequeueing more work and calling proc, since that might take time.

            // Check for more work. If there’s none, try to steal some before going to sleep.
            // This approach is a bit ham-fisted and could use improvement.
            entry = get_work(*info.available);
            if entry {
                // Decrement the semaphore for the work we just dequeued. (To reduce the number of unnecessary wakes.)
                wait_for(*info.available.semaphore);
            } else {
                // No work left - let’s steal some
                for i: info.work_steal_indices {
                    entry = get_work(*group.worker_info[i].available);
                    if entry {
                        if group.logging  Basic.log("'%' stole     work '%'  for thread % (worker %) at time % from worker %.\n", group.name, entry.logging_name, thread.index, info.worker_index, get_time(group), i);
                        // We can’t decrement the other thread’s semaphore here without introducing a race, so we leave it as it is.
                        break;
                    }
                }
            }
        } else {
            entry = null;
        }
    }

    return 0;
}


// The default get_time() routine that is used for logging unless the user
// provides a replacement.
get_time :: (group: *Thread_Group) -> float64 {
    if group.time_proc  return group.time_proc();
    return Basic.get_time();
}

shuffle :: (array: [] $T) {
    // We could do something more statistically correct here, but it probably requires more storage
    // (2 arrays?) so I am being lazybones for now.

    if array.count < 2 return;

    for i: 0..array.count-1 {
        j := random_get() % (array.count-1);
        Swap(*array[i], *array[j]);
    }
}

#import "Random";
