// Platform-independent thread routines.


// Enable DEBUG_MODE to have some extra assertions on your mutexes (that require
// a bit of extra storage).
// CACHE_LINE_SIZE is measured in bytes. This is used to pad the worker array in Thread_Group.
// If you don't know what to pass there, it's not too bad to leave it alone.

#module_parameters (LOAD_THREAD_GROUP := true)(CACHE_LINE_SIZE : s32 = 64, DO_RACE_DETECTOR := false);   // LOAD_THREAD_GROUP wil cause stuff to get added to the context, so you can disable this if you are loading after the context is finalized, until we solve some problems... 

#scope_module
DEBUG :: false;  // :DebugDisabled

#load "primitives.jai";

#if LOAD_THREAD_GROUP {
    #load "thread_group.jai";
}

#if DO_RACE_DETECTOR {
    Race_Detector :: #import "Race_Detector";
} else {
    Race_Detector :: false;
}

#scope_export

//
// If DEBUG is enabled, we support mutex ordering, so that you can detect
// potential deadlocks by assigning integer values to Mutexes. Then, the
// Mutexes can only be locked in descending order. Thus deadlock is impossible,
// because if the order of one pair of mutexes is descending, the opposite
// order would be ascending, and we prevented that. However, this restricts
// you to a subset of all possible things you might want to do with mutexes,
// so, it's optional.
//
Mutex_Order :: s32;

// :DebugDisabled
// DEBUG is currently disabled until we work out some stuff with #if and the Context.
// If you were using this, sorry for the inconvenience. Hopefully we will fix it before too long.
#if DEBUG {
    Mutex_Tracking :: struct {
        current_order        : Mutex_Order = -1;
        current_order_set_by : Source_Code_Location;
        current_name         := "";
        current_mutex_id     : *Per_OS_Critical_Section_Type;  // In Windows this is big, but you can't move it while locked, so the address serves to identify.
    }

    // #add_context mutex_tracking: Mutex_Tracking;

    #assert false, "DEBUG is disabled until we fix some stuff with Context and #if.";
}

// @Cleanup:
// thread_create and thread_destroy are kind of dumb right now.
// They just allocate and then call the real routines. Maybe we should
// just delete them?


//
// WARNING: On Windows, if you don't call timeBeginPeriod(1), you may get
// very laggy and jittery thread wake-ups. Windows is lame about this by default. We didn't
// want to make this module call that by default, but, beware.
//
#scope_module

Basic     :: #import "Basic";
operator- :: Basic.operator-;

assert    :: Basic.assert;
array_add :: Basic.array_add;

next_thread_index: u32 = 1;

#import "Atomics";
