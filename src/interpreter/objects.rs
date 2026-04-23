pub type IdentifierHash = usize;

#[repr(C)]
pub union Object {
    pub int: i32,
    pub uint: u32,
    pub long: u64,
    pub ulong: u64,
    pub float: f32,
    pub double: f64,

    pub identifier: IdentifierHash,
}