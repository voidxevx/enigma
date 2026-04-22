use crate::interpreter::objects::Object;

pub mod objects;

#[repr(C)]
struct RawInterpreter {
    _unused: [u8; 0]
}

unsafe extern "C" {
    unsafe fn new_interpreter() -> *mut RawInterpreter;
    unsafe fn destroy_interpreter(interpreter: *mut RawInterpreter);
    unsafe fn push_to_interpreter(interpreter: *mut RawInterpreter, data: Object);
    unsafe fn pop_from_interpreter(interpreter: *mut RawInterpreter) -> Object;
}

pub struct Interpreter {
    raw: *mut RawInterpreter
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            raw: unsafe { new_interpreter() },
        }
    }

    pub fn push(&self, data: Object) {
        unsafe {push_to_interpreter(self.raw, data); }
    }

    pub fn pop(&self) -> Object {
        unsafe {pop_from_interpreter(self.raw)}
    }
}

impl Drop for Interpreter {
    fn drop(&mut self) {
        unsafe {
            destroy_interpreter(self.raw);
        }
    }
}