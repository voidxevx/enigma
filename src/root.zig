//! # Enigma 
//! 
//! Abstract Syntax Tree generator

// =<Log>============================================================================================================
// * [4/17/2026]
//      - Started log.
//      - Fully implemented tokenization (i think), every thing works as intended (so far). 
//      - Started working on nodes playing around with manual vtables.
// =<Future>=========================================================================================================
// * [4/17/2026] - I have written the lexing algorithm before but I want to
//          play around using multithreading to make it faster.
//          My idea is that I have a thread-collection object that can be given
//          a set of threads and will hand them out to different branches while generating the tree.
//          Each branch stays completely secluded and never mutates shared data their won't be any race conditions.
// ===================================================================================================================

// MODULES -----
pub const lexing = @import("lexing/tokenization.zig");
pub const ast = @import("ast/ast.zig");
pub const literals = @import("literals.zig");
pub const operator = @import("operator.zig");
// ----- MODULES