# **ezDXT**
(easy DXT - *ee zee dee eks tee*)
### Tiny library for reading and encoding DXT/S3TC images.
//todo: DXT3 and DXT5
# Usage
### Prerequisites
- Latest Zig compiler (v9/v10-dev, 2022-05-04)
- Computer, preferrably functional
- Basic command-line interface competency
## As a static library
1. Compile with the following command:
    ```sh
    zig build -Drelease-fast
    ``` 
2. Get your file at `./zig-out/lib/`
    - `libezdxt.a` (Linux/MacOS/Other UNIX-likes)
    - `ezdxt.lib` (Windows)
3. (for C/C++ projects) use `./include/ezdxt.h(pp)`
## As a shared library
//todo
## As a Zig package
//todo
