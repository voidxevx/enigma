//! # Objects
//! 4/22/2026 - Nyx
//! 
//! An identical Zig implementation can be found at: ./objects.zig

/// Hashed Identifier
/// 
/// An identifier that was hashed into a smaller sequence to allow for more efficient memory management.
pub type IdentifierHash = usize;

#[repr(C)]
/// Interpreter Object
/// 
/// 8byte union of all possible types that an object stored by the interpreter can take.
/// The exact type that the object manifests as cannot be determined at runtime so compile time
/// type checks are required.
pub union Object {
    pub byte: i8,
    pub ubyte: u8,
    pub short: i16,
    pub ushort: u16,
    pub int: i32,
    pub uint: u32,
    pub long: u64,
    pub ulong: u64,
    pub float: f32,
    pub double: f64,

    /// Identifier
    /// 
    /// Works as either a variable name or a pointer
    pub identifier: IdentifierHash,
}