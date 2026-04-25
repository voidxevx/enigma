//! # Objects
//! 4/22/2026 - Nyx
//! 
//! An identical Zig implementation can be found at: ./objects.zig

/// Hashed Identifier
/// 
/// An identifier that was hashed into a smaller sequence to allow for more efficient memory management.
pub type IdentifierHash = usize;

pub enum Object {
    Byte(i8),
    UByte(u8),
    Short(i16),
    UShort(u16),
    Int(i32),
    UInt(u32),
    Long(i64),
    ULong(u64),

    Float(f32),
    Double(f64),

    Identifier(IdentifierHash),
}

pub enum ObjectRef {
    Byte(*mut i8),
    UByte(*mut u8),
    Short(*mut i16),
    UShort(*mut u16),
    Int(*mut i32),
    UInt(*mut u32),
    Long(*mut i64),
    ULong(*mut u64),

    Float(*mut f32),
    Double(*mut f64),

    Identifier(*mut IdentifierHash),
}

#[repr(C)]
pub struct RawObject {
    pub type_: ObjectType,
    pub raw: ObjectRaw,
}

#[repr(C)]
pub struct RawObjectRef {
    pub type_: ObjectType,
    pub raw: ObjectRawRef,
}

#[repr(u8)]
pub enum ObjectType {
    Byte,
    UByte,
    Short,
    UShort,
    Int,
    UInt,
    Long,
    ULong,

    Float,
    Double,

    Identifier,
}

#[repr(C)]
pub union ObjectRaw {
    byte: i8,
    ubyte: u8,
    short: i16,
    ushort: u16,
    int: i32,
    uint: u32,
    long: i64,
    ulong: u64,

    float: f32,
    double: f64,

    identifier: IdentifierHash,
}

#[repr(C)]
pub union ObjectRawRef {
    byte: *mut i8,
    ubyte: *mut u8,
    short: *mut i16,
    ushort: *mut u16,
    int: *mut i32,
    uint: *mut u32,
    long: *mut i64,
    ulong: *mut u64,

    float: *mut f32,
    double: *mut f64,

    identifier: *mut IdentifierHash,
}

impl Object {
    pub fn raw(self) -> RawObject {
        match self {
            Self::Byte(i) => return RawObject { type_: ObjectType::Byte, raw: ObjectRaw { byte: i}},
            Self::UByte(i) => return RawObject { type_: ObjectType::UByte, raw: ObjectRaw { ubyte: i } },
            Self::Short(i) => return RawObject { type_: ObjectType::Short, raw: ObjectRaw { short: i } },
            Self::UShort(i) => return RawObject { type_: ObjectType::UShort, raw: ObjectRaw { ushort: i } },
            Self::Int(i) => return RawObject { type_: ObjectType::Int, raw: ObjectRaw { int: i } },
            Self::UInt(i) => return RawObject { type_: ObjectType::UInt, raw: ObjectRaw { uint: i } },
            Self::Long(i) => return RawObject { type_: ObjectType::Long, raw: ObjectRaw { long: i } },
            Self::ULong(i) => return RawObject { type_: ObjectType::ULong, raw: ObjectRaw { ulong: i } },
            Self::Float(i) => return RawObject { type_: ObjectType::Float, raw: ObjectRaw { float: i } },
            Self::Double(i) => return RawObject { type_: ObjectType::Double, raw: ObjectRaw { double: i } },
            Self::Identifier(i) => return RawObject { type_: ObjectType::Identifier, raw: ObjectRaw { identifier: i } },
        }
    }
}

impl ObjectRef {
    pub fn raw(&self) -> RawObjectRef {
        match self {
            Self::Byte(i) => return RawObjectRef { type_: ObjectType::Byte, raw: ObjectRawRef { byte: *i }},
            Self::UByte(i) => return RawObjectRef { type_: ObjectType::UByte, raw: ObjectRawRef { ubyte: *i } },
            Self::Short(i) => return RawObjectRef { type_: ObjectType::Short, raw: ObjectRawRef { short: *i } },
            Self::UShort(i) => return RawObjectRef { type_: ObjectType::UShort, raw: ObjectRawRef { ushort: *i } },
            Self::Int(i) => return RawObjectRef { type_: ObjectType::Int, raw: ObjectRawRef { int: *i } },
            Self::UInt(i) => return RawObjectRef { type_: ObjectType::UInt, raw: ObjectRawRef { uint: *i } },
            Self::Long(i) => return RawObjectRef { type_: ObjectType::Long, raw: ObjectRawRef { long: *i } },
            Self::ULong(i) => return RawObjectRef { type_: ObjectType::ULong, raw: ObjectRawRef { ulong: *i } },
            Self::Float(i) => return RawObjectRef { type_: ObjectType::Float, raw: ObjectRawRef { float: *i } },
            Self::Double(i) => return RawObjectRef { type_: ObjectType::Double, raw: ObjectRawRef { double: *i } },
            Self::Identifier(i) => return RawObjectRef { type_: ObjectType::Identifier, raw: ObjectRawRef { identifier: *i } },
        }
    }
}

impl RawObject {
    pub fn pack(self) -> Object {
        unsafe {
            match self.type_ {
                ObjectType::Byte => Object::Byte(self.raw.byte),
                ObjectType::UByte => Object::UByte(self.raw.ubyte),
                ObjectType::Short => Object::Short(self.raw.short),
                ObjectType::UShort => Object::UShort(self.raw.ushort),
                ObjectType::Int => Object::Int(self.raw.int),
                ObjectType::UInt => Object::UInt(self.raw.uint),
                ObjectType::Long => Object::Long(self.raw.long),
                ObjectType::ULong => Object::ULong(self.raw.ulong),
                ObjectType::Float => Object::Float(self.raw.float),
                ObjectType::Double => Object::Double(self.raw.double),
                ObjectType::Identifier => Object::Identifier(self.raw.identifier),
            }
        }
    }
}

impl RawObjectRef {
    pub fn pack(&self) -> ObjectRef {
        unsafe {
            match self.type_ {
                ObjectType::Byte => ObjectRef::Byte(self.raw.byte),
                ObjectType::UByte => ObjectRef::UByte(self.raw.ubyte),
                ObjectType::Short => ObjectRef::Short(self.raw.short),
                ObjectType::UShort => ObjectRef::UShort(self.raw.ushort),
                ObjectType::Int => ObjectRef::Int(self.raw.int),
                ObjectType::UInt => ObjectRef::UInt(self.raw.uint),
                ObjectType::Long => ObjectRef::Long(self.raw.long),
                ObjectType::ULong => ObjectRef::ULong(self.raw.ulong),
                ObjectType::Float => ObjectRef::Float(self.raw.float),
                ObjectType::Double => ObjectRef::Double(self.raw.double),
                ObjectType::Identifier => ObjectRef::Identifier(self.raw.identifier),
            }
        }
    }
}

impl std::fmt::Display for Object {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Byte(i) => write!(f, "{}", i),
            Self::UByte(i) => write!(f, "{}", i),
            Self::Short(i) => write!(f, "{}", i),
            Self::UShort(i) => write!(f, "{}", i),
            Self::Int(i) => write!(f, "{}", i),
            Self::UInt(i) => write!(f, "{}", i),
            Self::Long(i) => write!(f, "{}", i),
            Self::ULong(i) => write!(f, "{}", i),
            Self::Float(i) => write!(f, "{}", i),
            Self::Double(i) => write!(f, "{}", i),
            Self::Identifier(i) => write!(f, "{}", i),
        }
    }
}


impl Into<Option<i8>> for Object {
    fn into(self) -> Option<i8> {
        match self {
            Self::Byte(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<u8>> for Object {
    fn into(self) -> Option<u8> {
        match self {
            Self::UByte(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<i16>> for Object {
    fn into(self) -> Option<i16> {
        match self {
            Self::Short(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<u16>> for Object {
    fn into(self) -> Option<u16> {
        match self {
            Self::UShort(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<i32>> for Object {
    fn into(self) -> Option<i32> {
        match self {
            Self::Int(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<u32>> for Object {
    fn into(self) -> Option<u32> {
        match self {
            Self::UInt(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<i64>> for Object {
    fn into(self) -> Option<i64> {
        match self {
            Self::Long(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<u64>> for Object {
    fn into(self) -> Option<u64> {
        match self {
            Self::ULong(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<f32>> for Object {
    fn into(self) -> Option<f32> {
        match self {
            Self::Float(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<f64>> for Object {
    fn into(self) -> Option<f64> {
        match self {
            Self::Double(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<IdentifierHash>> for Object {
    fn into(self) -> Option<IdentifierHash> {
        match self {
            Self::Identifier(i) => Some(i),
            _ => None,
        }
    }
}



impl Into<Option<i8>> for ObjectRef {
    fn into(self) -> Option<i8> {
        match self {
            Self::Byte(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<u8>> for ObjectRef {
    fn into(self) -> Option<u8> {
        match self {
            Self::UByte(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<i16>> for ObjectRef {
    fn into(self) -> Option<i16> {
        match self {
            Self::Short(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<u16>> for ObjectRef {
    fn into(self) -> Option<u16> {
        match self {
            Self::UShort(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<i32>> for ObjectRef {
    fn into(self) -> Option<i32> {
        match self {
            Self::Int(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<u32>> for ObjectRef {
    fn into(self) -> Option<u32> {
        match self {
            Self::UInt(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<i64>> for ObjectRef {
    fn into(self) -> Option<i64> {
        match self {
            Self::Long(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<u64>> for ObjectRef {
    fn into(self) -> Option<u64> {
        match self {
            Self::ULong(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<f32>> for ObjectRef {
    fn into(self) -> Option<f32> {
        match self {
            Self::Float(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<f64>> for ObjectRef {
    fn into(self) -> Option<f64> {
        match self {
            Self::Double(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<IdentifierHash>> for ObjectRef {
    fn into(self) -> Option<IdentifierHash> {
        match self {
            Self::Identifier(i) => unsafe { Some(*i) },
            _ => None,
        }
    }
}

impl Into<Option<*mut i8>> for ObjectRef {
    fn into(self) -> Option<*mut i8> {
        match self {
            Self::Byte(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut u8>> for ObjectRef {
    fn into(self) -> Option<*mut u8> {
        match self {
            Self::UByte(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut i16>> for ObjectRef {
    fn into(self) -> Option<*mut i16> {
        match self {
            Self::Short(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut u16>> for ObjectRef {
    fn into(self) -> Option<*mut u16> {
        match self {
            Self::UShort(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut i32>> for ObjectRef {
    fn into(self) -> Option<*mut i32> {
        match self {
            Self::Int(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut u32>> for ObjectRef {
    fn into(self) -> Option<*mut u32> {
        match self {
            Self::UInt(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut i64>> for ObjectRef {
    fn into(self) -> Option<*mut i64> {
        match self {
            Self::Long(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut u64>> for ObjectRef {
    fn into(self) -> Option<*mut u64> {
        match self {
            Self::ULong(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut f32>> for ObjectRef {
    fn into(self) -> Option<*mut f32> {
        match self {
            Self::Float(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut f64>> for ObjectRef {
    fn into(self) -> Option<*mut f64> {
        match self {
            Self::Double(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<*mut IdentifierHash>> for ObjectRef {
    fn into(self) -> Option<*mut IdentifierHash> {
        match self {
            Self::Identifier(i) => Some(i),
            _ => None,
        }
    }
}

impl Into<Option<&mut i8>> for ObjectRef {
    fn into(self) -> Option<&'static mut i8> {
        match self {
            Self::Byte(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut u8>> for ObjectRef {
    fn into(self) -> Option<&'static mut u8> {
        match self {
            Self::UByte(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut i16>> for ObjectRef {
    fn into(self) -> Option<&'static mut i16> {
        match self {
            Self::Short(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut u16>> for ObjectRef {
    fn into(self) -> Option<&'static mut u16> {
        match self {
            Self::UShort(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut i32>> for ObjectRef {
    fn into(self) -> Option<&'static mut i32> {
        match self {
            Self::Int(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut u32>> for ObjectRef {
    fn into(self) -> Option<&'static mut u32> {
        match self {
            Self::UInt(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut i64>> for ObjectRef {
    fn into(self) -> Option<&'static mut i64> {
        match self {
            Self::Long(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut u64>> for ObjectRef {
    fn into(self) -> Option<&'static mut u64> {
        match self {
            Self::ULong(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut f32>> for ObjectRef {
    fn into(self) -> Option<&'static mut f32> {
        match self {
            Self::Float(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut f64>> for ObjectRef {
    fn into(self) -> Option<&'static mut f64> {
        match self {
            Self::Double(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}

impl Into<Option<&mut IdentifierHash>> for ObjectRef {
    fn into(self) -> Option<&'static mut IdentifierHash> {
        match self {
            Self::Identifier(i) => unsafe { i.as_mut() },
            _ => None,
        }
    }
}
