
fn main() {
    println!("cargo:rustc-link-search=native=./zig-out/lib");

    println!("cargo:rustc-link-lib=dylib=enigma-core");
    println!("cargo:rustc-link-lib=dylib=enigma");
}