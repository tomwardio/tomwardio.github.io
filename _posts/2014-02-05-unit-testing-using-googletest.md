---
layout: post
title: Unit Testing using googletest
permalink: unit-testing-using-googletest
categories:
- Tech
tags:
- c++
- googletest
- gtest
- unit testing
- automation
---
A while back I was teaching myself various basic data structures and algorithms, as well as writing my own allocator classes, when I came to a point where I needed a simple way to unit test all my workings. I've used a couple of unit tests systems in the past ([boost](http://www.boost.org/doc/libs/1_35_0/libs/test/doc/components/utf/index.html) for instance) but always found that they didn't include a nice pretty printer, nor a simple way to write the tests.

Completely separately I've also been working on using [protocol buffers](https://code.google.com/p/protobuf/) at work for dynamic messaging between applications (more on this in the future) and noticed they used a thing called googletest. Long story short, after 30mins (maybe less) I had created my first unit test and was very happy with just how simple it is! It also has some really cool floating point test macros, which makes float comparisons a breeze.

# My First Unit Test

It really is very simple to use, here's a quick test I wrote for my quicksort function:

```cpp
TEST( Sorting, QuickSort )
{
    static int32_t numbersToSort[] = { 13, 13, 1, 150, 12, 7, 9, 10 };
    static size_t sortingLen = sizeof(numbersToSort) / sizeof(int32_t);

    Sorting::QuickSort( &numbersToSort, sortingLen );

    ASSERT_EQ( 1, numbersToSort[0]);
    ASSERT_TRUE( Sorting::Validate( &numbersToSort[0], sortingLen ) );
}
```

The "TEST" macro has two arguments, the first is the category the test is in (so for this case, it's "Sorting") the second is the name of the test. This will then basically build a static function which will automatically get added to a list of functions to test by the compiler using "magic". The body is whatever I want to test, so in this case the QuickSort function I've written. I then can test the results by using a nice collection of ASSERT macros, that allow me to test the output. Really really simple stuff!

Rather than pollute my main applications, I decided to put all my unit tests into a command line project, so that I can test stuff independently. I'm sure this would also work in an app as well, if done correctly. Anyway, here's the main() function I use:

```cpp
int32_t
main( int32_t argc, char** argv )
{
    ::testing::InitGoogleTest(&argc, argv);

    int32_t liReturnCode = RUN_ALL_TESTS();

    std::cout << "Press ENTER to continue...";
    std::cin.ignore( std::numeric_limits::max(), '\n' );

    return liReturnCode;
}
```

You basically just have to call "::testing::InitGoogleTest(&argc, argv)", then use the "RUN_ALL_TESTS()" macro to actually execute all the tests! How easy is that?!

Here's the output from my test framework (I've now written over 300 tests!). I really like the formatted output, and it also does some basic timings as well (though not enough for performance testing)

[![UnitTests](/uploads/posts/unit-testing-using-googletest/UnitTests-small.jpg)](/uploads/posts/unit-testing-using-googletest/UnitTests.jpg)

For anyone looking to do some C++ unit testing, I'd highly recommend this as your solution!
