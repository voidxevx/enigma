
#[repr(C)]
pub struct TestStruct {
    data: u64,
}

impl TestStruct {
    pub fn new(data: u64) -> Self {
        Self {
            data
        }
    }
}

unsafe extern "C" {
    pub fn use_test(st: *const TestStruct);
}