use enigma::{
    application::Application, 
    interpreter::{
        Interpreter, 
        objects::Object
    }
};

unsafe extern "C" {
    unsafe fn test_ast();
}

fn main() {
    unsafe {
        test_ast();
    }


    let mut interpreter = Interpreter::new();

    #[allow(unused)]
    let app = Application::new("Enigma");
    // app.main_loop();

    interpreter.push(Object::Int(32));
    let popped_val = interpreter.pop().unwrap();
    println!("Popped int: {}", popped_val);

    let id = interpreter.allocate(Object::Float(34.0));
    let val = interpreter.get(id);

    let v: &mut f32 = {
        let v: Option<&mut f32> = val.into();
        v.unwrap()
    };

    *v = 50.8;

    let val_2 = interpreter.get(id);
    let v_2: Option<f32> = val_2.into();
    assert_eq!(v_2, Some(50.8));
}
