import gleeunit
import gleeunit/should
import gleam/dict
import gleam/option.{None}
import solc/types

pub fn main() {
  gleeunit.main()
}

// Test basic type construction
pub fn types_test() {
  let source = types.Source(content: "contract Test {}")
  should.equal(source.content, "contract Test {}")
}

// Test error types
pub fn error_types_test() {
  let error = types.DownloadError("test error")
  case error {
    types.DownloadError(msg) -> should.equal(msg, "test error")
  }
}

// Test compilation input creation
pub fn compilation_input_test() {
  let source = types.Source(content: "contract HelloWorld {}")
  let sources = dict.from_list([#("HelloWorld.sol", source)])
  
  let output_selection = types.OutputSelection(
    selections: dict.from_list([
      #("*", dict.from_list([#("*", ["abi"])]))
    ])
  )
  
  let settings = types.CompilationSettings(
    output_selection: output_selection,
    optimizer: None,
    evm_version: None,
    libraries: None,
    remappings: None
  )
  
  let input = types.CompilationInput(
    language: "Solidity",
    sources: sources,
    settings: settings
  )
  
  should.equal(input.language, "Solidity")
}