
//
// Thread has program parameters that control whether mutex ordering is checked (this is 
// currently the parameter DEBUG, which defaults to false).
//
// When you enable DEBUG, if you assign order numbers to your mutexes, they will be checked
// to ensure they are only locked consistently with that order. This then means that you
// cannot have deadlocks in your program. (Deadlocks only can happen when two mutexes are
// acquired in opposite order, which is not possible if you only allow one order).
//
// That said, this is a runtime check, which means if some 'if' statement is not exercised,
// it might have a problem that we don't see. You could imagine making a metaprogram that
// tries to expand this to static checks. This isn't possible in all cases, but it may be
// possible in most cases.
//

// We can enable or disable DEBUG on the import directive:

#import "Thread"()(DEBUG=true);


mutex_fruit:      Mutex;
mutex_vegetables: Mutex;
mutex_chocolate:  Mutex;
mutex_water:      Mutex;

main :: () {

    // In order to use mutex order checking, we assign an order in 'init'.
    // We can also assign a debug name, which helps us know what the problem was
    // when we detect an error:
    
    init(*mutex_fruit,      "Fruit",     1);
    init(*mutex_vegetables, "Veggies",   2);
    init(*mutex_chocolate,  "Chocolate", 3);

    // We will not give mutex_water an order, so it defaults to -1, meaning not checked:
    init(*mutex_water,      "Water");
    
    // It is only legal to lock these mutexes in descending order. So, this is fine:

    print("\n");
    
    {
        lock(*mutex_chocolate);

        print("Doing chocolate stuff!\n");

        {
            lock(*mutex_vegetables);

            print("Doing vegetable stuff!\n");

            {
                lock(*mutex_fruit);
                print("Doing fruit stuff!\n");
                unlock(*mutex_fruit);
            }
            
            unlock(*mutex_vegetables);
        }
        
        unlock(*mutex_chocolate);
    }

    print("\n");

    // (By the way, it is a common pattern to use 'defer' to do scoped locking, which is why we put
    // the braces in that previous example, because you can convert it to):

    {
        lock(*mutex_chocolate);
        defer unlock(*mutex_chocolate);

        print("Doing chocolate stuff!\n");

        {
            lock(*mutex_vegetables);
            defer unlock(*mutex_vegetables);

            print("Doing vegetable stuff!\n");

            {
                lock(*mutex_fruit);
                defer unlock(*mutex_fruit);
                
                print("Doing fruit stuff!\n");
            }
        }
    }
    
    // (... which is much nicer in procedures with many return points, or, just generally to make sure
    // you don't forget the unlock.)


    print("\n");
    
    // The following thing would be illegal, because chocolate must always be locked before vegetables.
    // We have it in an 'if 0' so that it doesn't run and cause the program to abort.
    // But you can change it to 'if 1' and see it happen:

    if 0 {
        lock(*mutex_vegetables);
        defer unlock(*mutex_vegetables);

        print("Doing vegetable stuff!\n");
        
        {
            lock(*mutex_chocolate);
            defer unlock(*mutex_chocolate);

            print("Doing chocolate stuff!\n");
        }
    }


    // The exception to the strictly-decreasing-order rule is, we let you re-lock the same mutex
    // multiple times in succession. This just makes some kinds of code easier to write.

    {
        lock(*mutex_fruit);

        // Locking again is okay and won't trip the order checking.
        // (You can imagine that this actually happens down in a function we are calling from
        // the current one, or whatever).
        lock(*mutex_fruit);
        lock(*mutex_fruit);

        unlock(*mutex_fruit);
        unlock(*mutex_fruit);
        unlock(*mutex_fruit);
    }

    // Recall that mutex_water did not set its order checking.
    // Thus it is unordered with respect to all other mutexes, and you can
    // make deadlocks with it.


    // First we'll lock vegetables then water:
    {
        lock(*mutex_vegetables);
        defer unlock(*mutex_vegetables);

        print("Doing vegetables stuff!\n");

        {
            lock(*mutex_water);
            defer unlock(*mutex_water);

            print("Doing water stuff!\n");
        }
    }

    print("\n");
    
    // Now we'll lock water then vegetables:
    {
        lock(*mutex_water);
        defer unlock(*mutex_water);

        print("Doing water stuff!\n");
    
        {
            lock(*mutex_vegetables);
            defer unlock(*mutex_vegetables);

            print("Doing vegetables stuff!\n");
        }
    }


    // If two different threads decide to do these things at the same time,
    // they can deadlock!


    // If your Mutex is ordered, we check to make sure that its unlock
    // is not swapped with the unlock of any other ordered mutex. For example,
    // the following will be caught if you change the 'if 0' to a 1:

    if 0 {
        lock(*mutex_vegetables);
        lock(*mutex_fruit);
        
        unlock(*mutex_vegetables);  // Out of order!
        unlock(*mutex_fruit);
    }        
}

#import "Basic";

  
