# **ezDXT**
(easy DXT - *ee zee dee eks tee*)
### Tiny library for reading and encoding DXT/S3TC images.

## **Disclaimer**
**This library was created to help the OpenSrc project and such the only data i've tested with is Source Engine VTF-compatible DXT data. I know zero other instances where DXT compression is used and so i have zero other references for how DXT should behave.**
Example: according to the [OpenGL Wiki](https://www.khronos.org/opengl/wiki/S3_Texture_Compression), in DXT3 *"color0 is always assumed to be less than color1 in terms of determining how to use the codes to extract the color value,"* but this behavior does not match the Source Engine, as tested by the **VTFEdit** and **no_vtf** tools.
# Usage
### Prerequisites
- Zig 0.13.0
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
