//! Rust build script
//! 4/22/2026 - Nyx

fn main() {

    // Link against the generated zig dynamic lib
    println!("cargo:rustc-link-search=native=./zig-out/lib");
    println!("cargo:rustc-link-lib=dylib=enigma-core");

    // Tells the generated executable to search its origin
    // directory for required dynamic libs
    #[cfg(target_os = "linux")]
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN");
    #[cfg(target_os = "macos")]
    println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path");
}