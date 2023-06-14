thread_group: Thread_Group;

pool: Pool;

main :: () {
    // First, we initialize the Thread_Group that we will use to do the work.
    init_thread_group();

    // Schedule work for all the threads.
    // Because this is an example, and we don't want to complicate it with
    // lots of code that is beside the point, the work that we will give to our threads
    // is very simple: it will be to sum the range of integers from 1 to N, where N is
    // chosen randomly each time. We will do this for many N.

    // In order to use CPU and make it seem like the threads are really doing something,
    // they will compute the answer by iterating in a loop and summing the integers.

    // But, Karl Friedrich Gauss once figured out that you don't have to do this; you can
    // just compute N(N+1)/2.

    // Our test here will get back the answers from the threads and verify that the
    // answers are correct by comparing them to Gauss' result.

    // First, let's start the thread group:

    start(*thread_group);

    // We want to give lots of units of work to the thread group. The thread group will
    // then distribute that work to its various threads.

    // These units of work need to occupy memory that stays alive until the worker thread
    // finishes computing its result and returns the work back to us. In many programs,
    // the work will go for a while, for example across many frames of an interactive
    // application, so, let's use a Pool to allocate the work.

    set_allocators(*pool);  // Init the Pool to use context.allocator.

    // The struct for the work is just 'Summation', defined below after the end of main().
    // (It needs to be visible to our worker procedure to see it, so we don't
    // declare it here).

    allocator: Allocator;
    allocator.proc = pool_allocator_proc;
    allocator.data = *pool;

    for 1..NUM_WORK_ITEMS {
        work := New(Summation, allocator=allocator);

        // random_get returns a u64, so, to keep our jobs reasonable, let's only take a few bits.
        work.input_number = random_get() & 0xFF_FFFF;
        if work.input_number == 0  work.input_number = 1;

        // Give the work to the Thread_Group.
        add_work(*thread_group, work, tprint("Work item %", it));
    }

    // Now that we have given the Thread_Group all the work, we can go about
    // our business.

    // Occasionally as our program runs, we should call get_completed_work()
    // to see what is done, and to do whatever processing we need.

    // Because this is a simple example, we'll just make a loop that sleeps
    // and keeps checking for finished work. Instead of sleeping, a real program
    // might be drawing the display, performing a simulation, and so forth.

    // We will exit the loop when we have received as many completed pieces
    // of work as we issued.

    work_remaining := NUM_WORK_ITEMS;

    while work_remaining > 0 {
        sleep_milliseconds(10);

        results := get_completed_work(*thread_group);

        for results {
            // The work we receive back here, in 'results', is done,
            // and will no longer be touched by either the threads or
            // the Thread_Group utility functions. We can deallocate our
            // data structures if we want (though in this case, to be
            // efficient, we allocated them with a Pool, so there is no
            // need to deallocate them individually).

            // Here we check the sums, to see if they are correct.

            // So that we don't have to make Thread_Group polymorphic,
            // the work pointer is just a *void, and we cast it here.

            summation := cast(*Summation) it;

            n := summation.input_number;
            desired_result := (n * (n + 1)) / 2;

            assert(summation.output_sum == desired_result);

            log("Successful result: Sum(1..%) == %.\n", n, desired_result);
        }

        work_remaining -= results.count;

        // A nontrivial program would probably use lots of Temporary_Storage
        // and thus reset it here. Since the return value of get_completed_work()
        // uses Temporary_Storage, we will go ahead and do this.

        reset_temporary_storage();
    }

    // When we are done, we shut down the Thread_Group.
    shutdown(*thread_group);

    print("Done!\n");
}


// Summation is the struct representing the work that we pass to our Thread_Group.
Summation :: struct {
    input_number: u64;  // The max number of the sum; the thread will sum 1..input_number.

    output_sum:   u64;  // Our thread procedure will write the result here.
}

init_thread_group :: () {
    // We want to make about as many threads as we have CPUs. More than that
    // will overwhelm our computer with context-switching waste work!
    num_cpus := get_number_of_processors();

    assert(num_cpus >= 1);
    if num_cpus > 200  num_cpus = 200;  // Clamp to a value that is reasonable as of 2021, in case we get weird data.

    #if (OS == .WINDOWS) || (OS == .LINUX) {
        // This routine reports hyperthreads, so, divide by two, because of Intel marketing.
        num_cpus /= 2;
    }

    // In a typical program, you want the "main thread" to be able to use a CPU, so,
    // only allocate as many threads as we have other CPUs.
    // Launch at least 2 threads, because for this example, we want to show multiple threads
    // running at the same time.
    num_threads := max(num_cpus - 1, 2);

    log("This machine reports % CPUs; starting % threads.\n", num_cpus, num_threads);

    init(*thread_group, num_threads, summation_proc);

    // After initializing a Thread_Group, there are various data members you can set
    // to control behavior. See the definition of Thread_Group in modules/Thread.
    thread_group.name    = "Example";
    thread_group.logging = DO_LOGGING;

    {
        // You are free to set the Thread.user_data member on any of the threads created by the group.
        // But ... you have to do that before calling start(). Here we will just set a dummy user_data,
        // to show it's working.

        Dummy_Data :: struct {
            name := "Lord Dimwit Flathead the Excessive";
        }

        dummy_data := New(Dummy_Data);

        for * thread_group.worker_info {
            it.thread.data = dummy_data;
        }
    }
}

// summation_proc will be called by the Thread_Group, once for each
// Summation that we gave it, each time in a thread that is different from
// the main thread.
summation_proc :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
    // So that we don't have to make Thread_Group polymorphic, work is just a *void,
    // but you can cast it to the expected type here.

    summation := cast(*Summation) work;

    result: u64;
    for 1..summation.input_number {
        result += it;
    }

    summation.output_sum = result;

    // We return .CONTINUE to tell the Thread_Group that we should keep running.
    // Returning .STOP will stop this thread, and we don't want to do that.
    return .CONTINUE;
}

// Just to see how the example works, by default we set NUM_WORK_ITEMS to 10.
// For a more-serious test, you might try a much larger number of work items.
// This will be spammy so you might want to think about setting
// DO_LOGGING to false.

SERIOUS_TEST :: false;
#if SERIOUS_TEST {
    NUM_WORK_ITEMS :: 10000;
} else {
    NUM_WORK_ITEMS :: 10;
}

DO_LOGGING :: true;

#import "Basic";
#import "System";
#import "Thread";
#import "Pool";
#import "Random";
