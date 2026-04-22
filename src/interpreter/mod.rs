pub mod objects;

#[repr(C)]
pub struct Interpreter {
    _unused: [u8; 0]
}

unsafe extern "C" {
    pub unsafe fn new_interpreter() -> *mut Interpreter;
    pub unsafe fn destroy_interpreter(interpreter: *mut Interpreter);
}