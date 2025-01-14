# **ezDXT**

(easy DXT - *ee zee dee eks tee*)

A tiny library for reading and encoding DXT/S3TC images.


# Usage
This project depends on Zig 0.13.0 (latest stable release as of 2025-01-14).

Download from a package manager or at [ziglang.org/download](https://ziglang.org/download/)

1. Compile with the following command:
    ```sh
    zig build -Drelease-fast
    ``` 
2. Get your file at `./zig-out/lib/`
    - `libezdxt.a` (Linux/MacOS/Other UNIX-likes)
    - `ezdxt.lib` (Windows)
3. (for C/C++ projects) use `./include/ezdxt.h(pp)`

