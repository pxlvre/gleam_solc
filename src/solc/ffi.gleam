// FFI bindings for Solidity compiler JavaScript integration

import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}

// External JavaScript module reference type
pub type SoljsonModule

// FFI function declarations for JavaScript interop
@external(javascript, "../ffi/solc_ffi.mjs", "load_solc_module")
pub fn load_solc_module(path: String) -> Result(SoljsonModule, String)

@external(javascript, "../ffi/solc_ffi.mjs", "get_solc_version")
pub fn get_solc_version(soljson: SoljsonModule) -> Result(String, String)

@external(javascript, "../ffi/solc_ffi.mjs", "get_solc_license")
pub fn get_solc_license(soljson: SoljsonModule) -> Result(String, String)

@external(javascript, "../ffi/solc_ffi.mjs", "compile_solidity")
pub fn compile_solidity(
  soljson: SoljsonModule,
  input_json: String,
) -> Result(String, String)

@external(javascript, "../ffi/solc_ffi.mjs", "download_solc_release")
pub fn download_solc_release(
  url: String,
  path: String,
) -> Promise(Result(String, String))

@external(javascript, "../ffi/solc_ffi.mjs", "fetch_release_list")
pub fn fetch_release_list() -> Promise(Result(Dynamic, String))

@external(javascript, "../ffi/solc_ffi.mjs", "file_exists")
pub fn file_exists(path: String) -> Bool
