//! Org-Asm Procedures 
//! 4/26/2026 - Nyx

pub const Procedure = enum(u8) {
    /// Move - MOV <d> <r>
    MOV,

    /// Stack Push - PUSH <d>
    PUSH,

    /// Stack Pop - POP <b> <r>
    POP,
};

pub const Tag = enum(u8) {
    /// Program - PROG <root/mod>
    PROG,

    /// Procedure - PROC <ident>
    PROC,
};