use enigma::{application::Application, interpreter::{destroy_interpreter, new_interpreter, objects::{Object, test_objects}}, test::TestStruct};

unsafe extern "C" {
    unsafe fn zig_test();
    unsafe fn c_test();
    unsafe fn cpp_test();
    unsafe fn c_use_test(st: *const TestStruct);
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
    let interp = unsafe {new_interpreter()};

    #[allow(unused)]
    let app = Application::new("Enigma");
    // app.main_loop();

    unsafe {
        let test_st = TestStruct::new(34);
        c_use_test(&test_st);

        let obj = Object {int: 32};
        test_objects(obj);
        destroy_interpreter(interp);
    }
}
