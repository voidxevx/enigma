//! # Objects
//! 4/22/2026 - Nyx
//! 
//! An identical Rust implementation can be found at: ./objects.rs

/// Hashed Identifier
/// 
/// An identifier that was hashed into a smaller sequence to allow for more efficient memory management.
pub const IdentifierHash = usize;

/// Interpreter Object
/// 
/// 8byte union of all possible types that an object stored by the interpreter can take.
/// The exact type that the object manifests as cannot be determined at runtime so compile time
/// type checks are required.
pub const Object = extern union {
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,
    float: f32,
    double: f64,

    /// Identifier
    /// 
    /// Works as either a variable name or a pointer
    identifier: IdentifierHash,
};

