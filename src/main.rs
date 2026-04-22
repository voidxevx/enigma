use enigma::{application::Application, interpreter::{Interpreter, objects::{Object}}};

unsafe extern "C" {
    unsafe fn zig_test();
}

fn rust_test() {
    println!("Hello from rust!");
}

fn main() {
    rust_test();
    unsafe {
        zig_test();
    }

    let interpreter = Interpreter::new();

    #[allow(unused)]
    let app = Application::new("Enigma");
    // app.main_loop();

    interpreter.push(Object { int: 70 });
    let popped_val = interpreter.pop();
    unsafe {
        println!("Popped int: {}", popped_val.int);
    }
}
