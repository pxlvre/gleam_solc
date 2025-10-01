// Gleam Solidity Compiler Bindings
// 
// This module provides a high-level API for compiling Solidity contracts
// with support for multiple inheritance, error handling, and modern Solidity versions.

import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/list
import gleam/javascript/promise.{type Promise}
import solc/types.{type SolcError, type SolcWrapper, type CompilationInput, type CompilationOutput}
import solc/download
import solc/wrapper

// Download and load a Solidity compiler
pub fn load_solc(path: String, version: Option(String)) -> Promise(Result(SolcWrapper, SolcError)) {
  case download.solc_exists(path) {
    True -> {
      // File exists, try to load it
      promise.resolve(wrapper.load_wrapper(path))
    }
    False -> {
      // Download first, then load
      use download_result <- promise.map(download.download(path, version))
      case download_result {
        Ok(_filename) -> wrapper.load_wrapper(path)
        Error(err) -> Error(err)
      }
    }
  }
}

// Compile Solidity source code with simple interface
pub fn compile_simple(
  solc: SolcWrapper,
  contract_name: String,
  source_code: String
) -> Result(CompilationOutput, SolcError) {
  let input = create_simple_input(contract_name, source_code)
  let input_json = encode_input(input)
  
  case input_json {
    Ok(json_string) -> solc.compile(json_string)
    Error(msg) -> Error(types.InvalidInput("Failed to encode input: " <> msg))
  }
}

// Compile multiple Solidity files
pub fn compile_multiple(
  solc: SolcWrapper,
  sources: dict.Dict(String, String)
) -> Result(CompilationOutput, SolcError) {
  let input = create_multiple_input(sources)
  let input_json = encode_input(input)
  
  case input_json {
    Ok(json_string) -> solc.compile(json_string)
    Error(msg) -> Error(types.InvalidInput("Failed to encode input: " <> msg))
  }
}

// Create a simple compilation input for a single contract
fn create_simple_input(contract_name: String, source_code: String) -> CompilationInput {
  let source = types.Source(content: source_code)
  let sources = dict.from_list([#(contract_name, source)])
  
  let output_selection = types.OutputSelection(
    selections: dict.from_list([
      #("*", dict.from_list([
        #("*", ["abi", "evm.bytecode", "evm.deployedBytecode", "metadata"])
      ]))
    ])
  )
  
  let settings = types.CompilationSettings(
    output_selection: output_selection,
    optimizer: Some(types.OptimizerSettings(enabled: True, runs: 200)),
    evm_version: None,
    libraries: None,
    remappings: None
  )
  
  types.CompilationInput(
    language: "Solidity",
    sources: sources,
    settings: settings
  )
}

// Create compilation input for multiple files
fn create_multiple_input(sources: dict.Dict(String, String)) -> CompilationInput {
  let gleam_sources = dict.map_values(sources, fn(_, content) {
    types.Source(content: content)
  })
  
  let output_selection = types.OutputSelection(
    selections: dict.from_list([
      #("*", dict.from_list([
        #("*", ["abi", "evm.bytecode", "evm.deployedBytecode", "metadata"])
      ]))
    ])
  )
  
  let settings = types.CompilationSettings(
    output_selection: output_selection,
    optimizer: Some(types.OptimizerSettings(enabled: True, runs: 200)),
    evm_version: None,
    libraries: None,
    remappings: None
  )
  
  types.CompilationInput(
    language: "Solidity",
    sources: gleam_sources,
    settings: settings
  )
}

// Encode compilation input to JSON string
fn encode_input(input: CompilationInput) -> Result(String, String) {
  // TODO: Implement proper JSON encoding
  // For now, return a basic structure
  let json_obj = json.object([
    #("language", json.string(input.language)),
    #("sources", encode_sources(input.sources)),
    #("settings", encode_settings(input.settings))
  ])
  
  Ok(json.to_string(json_obj))
}

// Encode sources to JSON
fn encode_sources(sources: dict.Dict(String, types.Source)) -> json.Json {
  let source_pairs = dict.to_list(sources)
  let json_pairs = list.map(source_pairs, fn(pair) {
    let #(name, source) = pair
    #(name, json.object([
      #("content", json.string(source.content))
    ]))
  })
  json.object(json_pairs)
}

// Encode settings to JSON
fn encode_settings(settings: types.CompilationSettings) -> json.Json {
  json.object([
    #("outputSelection", encode_output_selection(settings.output_selection))
  ])
}

// Encode output selection to JSON
fn encode_output_selection(selection: types.OutputSelection) -> json.Json {
  let selection_pairs = dict.to_list(selection.selections)
  let json_pairs = list.map(selection_pairs, fn(pair) {
    let #(file, contracts) = pair
    let contract_pairs = dict.to_list(contracts)
    let contract_json_pairs = list.map(contract_pairs, fn(contract_pair) {
      let #(contract, outputs) = contract_pair
      #(contract, json.array(from: outputs, of: json.string))
    })
    #(file, json.object(contract_json_pairs))
  })
  json.object(json_pairs)
}
