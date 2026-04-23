use enigma::{
    application::Application, 
    interpreter::{
        Interpreter, 
        objects::Object
    }
};

fn main() {
    let mut interpreter = Interpreter::new();

    #[allow(unused)]
    let app = Application::new("Enigma");
    // app.main_loop();

    interpreter.push(Object { int: 70 });
    let popped_val = interpreter.pop().unwrap();
    unsafe {
        println!("Popped int: {}", popped_val.int);
    }

    let id = interpreter.allocate(Object { int: 45 });
    assert_eq!(id, 0);
    let data = interpreter.get_mut(id);
    unsafe {
        assert_eq!(data.int, 45);
        data.int = 90;
    }

    let data_ch = interpreter.get(id);
    unsafe {
        assert_eq!(data_ch.int, 90);
    }
}
