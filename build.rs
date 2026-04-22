
fn main() {
    println!("cargo:rustc-link-search=native=./zig-out/lib");

    println!("cargo:rustc-link-lib=dylib=enigma-core");
    println!("cargo:rustc-link-lib=dylib=enigma");

    #[cfg(target_os = "linux")]
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN");
    #[cfg(target_os = "macos")]
    println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path");
}