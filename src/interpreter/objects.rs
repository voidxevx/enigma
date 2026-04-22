
unsafe extern "C" {
    pub unsafe fn test_objects(obj: Object);
}

#[repr(C)]
pub union Object {
    pub int: i32,
    pub uint: u32,
    pub long: u64,
    pub ulong: u64,
    pub float: f32,
    pub double: f64,
}