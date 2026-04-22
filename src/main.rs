use enigma::{application::Application, interpreter::{Interpreter, objects::{Object}}};

fn main() {
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
