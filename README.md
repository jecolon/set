# set
A Set data structure implementation in Zig

This is a simple and thin layer over a normal `std.AutoHashMap` of the given key type and `void` as the value type.
Checkout the tests in `src/set.zig` for sample usage. You'll also find doc comments on the public API.

## Integrating into your project


```
$ cd <path to your project root>
$ mkdir libs
$ cd libs
$ git clone https://github.com/jecolon/set 
$ cd ..
$ vim build.exe
```

In `build.exe` add to your `exe` or `lib`

```
exe.addPackagePath("set", "libs/set/src/set.zig");
```

Now you can `@import("set")` in your files.

