
unsafe extern "C" {
    unsafe fn zig_test();
    unsafe fn c_test();
    unsafe fn cpp_test();
}

fn rust_test() {
    println!("Hello from rust!");
}

fn main() {
    rust_test();
    unsafe {
        zig_test();
        c_test();
        cpp_test();
    }
}
