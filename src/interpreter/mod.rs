//! # Interpreter 
//! 4/22/2026 - Nyx
//! 
//! The interpreter is not exactly the interpreter. The interpreter is designed 
//! to be passed around during execution to handle dynamically allocated memory and
//! to store quick access data for computations. The interpreter doesn't directly 
//! execute and commands.
//! 
//! The Interpreter has a stack array and a HeapSparseSet to emulate that of a CPU.

// INCLUDES -----
use crate::interpreter::objects::{
    IdentifierHash, 
    Object
};
// ----- INCLUDES

// MODULES -----
pub mod objects;
// ----- MODULES


/// Raw opaque Interpreter pointer wrapper.
/// 
/// Passed directly into ffi function.
#[repr(C)]
struct RawInterpreter {
    _unused: [u8; 0]
}

// FFI BINDINGS -----
unsafe extern "C" {
    unsafe fn new_interpreter() -> *mut RawInterpreter;
    unsafe fn destroy_interpreter(interpreter: *mut RawInterpreter);
    unsafe fn push_to_interpreter(interpreter: *mut RawInterpreter, data: Object);
    unsafe fn pop_from_interpreter(interpreter: *mut RawInterpreter) -> Object;
    unsafe fn is_interpreter_stack_empty(interpreter: *const RawInterpreter) -> bool;
    unsafe fn flush_interpreter(interpreter: *mut RawInterpreter);
    unsafe fn interpreter_allocate(interpreter: *mut RawInterpreter, data: Object) -> IdentifierHash;
    unsafe fn interpreter_free(interpreter: *mut RawInterpreter, id: IdentifierHash);
    unsafe fn interpreter_get(interpreter: *const RawInterpreter, id: IdentifierHash) -> *const Object;
    unsafe fn interpreter_get_mut(interpreter: *mut RawInterpreter, id: IdentifierHash) -> *mut Object;
}
// ----- FFI BINDINGS


/// Runtime Interpreter Memory handler
/// 
/// Handles the dynamic memory allocations for 
/// the interpreted byte code.
/// 
/// This is a wrapper that implements rust 
/// versions of the zig Interpreter. This can 
/// safely be passed between the ABI.
/// 
/// # Example
/// 
/// ## Rust:
/// 
/// ```
/// use enigma::interpreter::{objects::Object, Interpreter};
/// 
/// let mut interpreter = Interpreter::new();
/// interpreter.push(Object { int: 90});
/// let val = interpreter.pop().unwrap();
/// 
/// let id = interpreter.allocate(val);
/// 
/// let ptr: &Object = interpreter.get(id);
/// ```
/// 
/// ## Zig:
/// 
/// ```zig
/// const Interpreter = @import("interpreter.zig");
/// 
/// var interpreter: Interpreter = try .init();
/// defer interpreter.deinit();
/// 
/// try interpreter.push(.{.int = 90});
/// const val = interpreter.pop().?;
/// 
/// const id = try interpreter.allocate(val);
/// 
/// const ptr = interpreter.get(id);
/// ```
pub struct Interpreter {
    raw: *mut RawInterpreter
}

impl Interpreter {
    #[inline(always)]
    pub fn new() -> Self {
        Self {
            raw: unsafe { new_interpreter() },
        }
    }

    #[inline(always)]
    /// Pushes an object to the top of the stack
    /// 
    /// # Example
    /// 
    /// ```
    /// use enigma::interpreter::{objects::Object, Interpreter};
    /// 
    /// let mut interpreter = Interpreter::new();
    /// interpreter.push(Object { int: 50 });
    /// ```
    pub fn push(&mut self, data: Object) {
        unsafe {push_to_interpreter(self.raw, data); }
    }

    #[inline(always)]
    /// Pops an object from the top of the stack
    /// 
    /// # Example
    /// 
    /// ```
    /// use enigma::interpreter::{objects::Object, Interpreter};
    /// 
    /// let mut interpreter = Interpreter::new();
    /// interpreter.push(Object { int: 50 });
    /// 
    /// let data: Object = interpreter.pop.unwrap();
    /// ```
    pub fn pop(&mut self) -> Option<Object> {
        unsafe {
            if is_interpreter_stack_empty(self.raw) {
                return None;
            }

            Some(pop_from_interpreter(self.raw))
        }
    }

    #[inline(always)]
    /// Flushes the stack removing all data and resetting its capacity 
    pub fn flush(&mut self) {
        unsafe {flush_interpreter(self.raw);}
    }

    #[inline(always)]
    /// Frees a piece of allocated heap memory by its identifier pointer.
    pub fn allocate(&mut self, data: Object) -> IdentifierHash {
        unsafe {interpreter_allocate(self.raw, data)}
    }

    #[inline(always)]
    /// Frees a piece of allocated heap memory by its identifier pointer.
    pub fn free(&mut self, id: IdentifierHash) {
        unsafe { interpreter_free(self.raw, id); }
    }

    #[inline(always)]
    /// Gets an immutable pointer to a heap allocated piece of memory.
    pub fn get(&self, id: IdentifierHash) -> &Object {
        unsafe { 
            let data = interpreter_get(self.raw, id);
            return data.as_ref().unwrap();
        }
    }

    #[inline(always)]
    /// Gets a mutable pointer to a heap allocated piece of memory.
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