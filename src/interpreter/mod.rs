use crate::interpreter::objects::{IdentifierHash, Object};

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
    unsafe fn flush_interpreter(interpreter: *mut RawInterpreter);
    unsafe fn interpreter_allocate(interpreter: *mut RawInterpreter, data: Object) -> IdentifierHash;
    unsafe fn interpreter_free(interpreter: *mut RawInterpreter, id: IdentifierHash);
    unsafe fn interpreter_get(interpreter: *const RawInterpreter, id: IdentifierHash) -> *const Object;
    unsafe fn interpreter_get_mut(interpreter: *mut RawInterpreter, id: IdentifierHash) -> *mut Object;
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

    pub fn push(&mut self, data: Object) {
        unsafe {push_to_interpreter(self.raw, data); }
    }

    pub fn pop(&mut self) -> Object {
        unsafe {pop_from_interpreter(self.raw)}
    }

    pub fn flush(&mut self) {
        unsafe {flush_interpreter(self.raw);}
    }

    pub fn allocate(&self, data: Object) -> IdentifierHash {
        unsafe {interpreter_allocate(self.raw, data)}
    }

    pub fn free(&mut self, id: IdentifierHash) {
        unsafe { interpreter_free(self.raw, id); }
    }

    pub fn get(&self, id: IdentifierHash) -> &Object {
        unsafe { 
            let data = interpreter_get(self.raw, id);
            return data.as_ref().unwrap();
        }
    }

    pub fn get_mut(&mut self, id: IdentifierHash) -> &mut Object {
        unsafe {
            let data = interpreter_get_mut(self.raw, id);
            return data.as_mut().unwrap();
        }
    }
}

impl Drop for Interpreter {
    fn drop(&mut self) {
        unsafe {
            destroy_interpreter(self.raw);
        }
    }
}