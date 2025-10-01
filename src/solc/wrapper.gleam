// Solidity compiler wrapper implementation

import gleam/json
import gleam/dict
import gleam/result
import gleam/dynamic/decode
import gleam/option.{None}
import solc/types.{type SolcError, type SolcWrapper, type CompilationOutput}
import solc/ffi.{type SoljsonModule}

// Create a wrapper around a loaded solc module
pub fn create_wrapper(soljson: SoljsonModule) -> Result(SolcWrapper, SolcError) {
  // Test that the module is valid by getting version
  case ffi.get_solc_version(soljson) {
    Ok(_version) -> {
      let wrapper = types.SolcWrapper(
        version: fn() { get_version(soljson) },
        license: fn() { get_license(soljson) }, 
        compile: fn(input) { compile_standard(soljson, input) }
      )
      Ok(wrapper)
    }
    Error(msg) -> Error(types.FFIError("Invalid solc module: " <> msg))
  }
}

// Load a solc wrapper from file path
pub fn load_wrapper(path: String) -> Result(SolcWrapper, SolcError) {
  case ffi.load_solc_module(path) {
    Ok(soljson) -> create_wrapper(soljson)
    Error(msg) -> Error(types.FFIError("Failed to load module: " <> msg))
  }
}

// Get version string from solc module
fn get_version(soljson: SoljsonModule) -> String {
  case ffi.get_solc_version(soljson) {
    Ok(version) -> version
    Error(_) -> "unknown"
  }
}

// Get license string from solc module  
fn get_license(soljson: SoljsonModule) -> String {
  case ffi.get_solc_license(soljson) {
    Ok(license) -> license
    Error(_) -> "unknown"
  }
}

// Compile Solidity using standard JSON interface
fn compile_standard(soljson: SoljsonModule, input: String) -> Result(CompilationOutput, SolcError) {
  case ffi.compile_solidity(soljson, input) {
    Ok(output_json) -> {
      parse_compilation_output(output_json)
      |> result.map_error(fn(msg) { types.CompilationFailed("Failed to parse output: " <> msg) })
    }
    Error(msg) -> Error(types.CompilationFailed("Compilation failed: " <> msg))
  }
}

// Parse JSON compilation output into Gleam types
fn parse_compilation_output(json_string: String) -> Result(CompilationOutput, String) {
  case json.parse(json_string, compilation_output_decoder()) {
    Ok(output) -> Ok(output)
    Error(_) -> Error("Invalid JSON output")
  }
}

// Decoder for CompilationOutput
fn compilation_output_decoder() -> decode.Decoder(CompilationOutput) {
  use sources <- decode.optional_field("sources", None, decode.optional(sources_decoder()))
  use contracts <- decode.optional_field("contracts", None, decode.optional(contracts_decoder()))
  use errors <- decode.optional_field("errors", None, decode.optional(errors_decoder()))
  decode.success(types.CompilationOutput(
    sources: sources,
    contracts: contracts,
    errors: errors
  ))
}

// Decoder for sources dictionary
fn sources_decoder() -> decode.Decoder(dict.Dict(String, types.SourceInfo)) {
  decode.dict(decode.string, source_info_decoder())
}

// Decoder for source info
fn source_info_decoder() -> decode.Decoder(types.SourceInfo) {
  use id <- decode.optional_field("id", 0, decode.int)
  decode.success(types.SourceInfo(id: id, ast: None))
}

// Decoder for contracts dictionary
fn contracts_decoder() -> decode.Decoder(dict.Dict(String, dict.Dict(String, types.Contract))) {
  decode.dict(decode.string, decode.dict(decode.string, contract_decoder()))
}

// Decoder for contract
fn contract_decoder() -> decode.Decoder(types.Contract) {
  use abi <- decode.optional_field("abi", [], decode.list(abi_item_decoder()))
  use evm <- decode.field("evm", evm_decoder())
  use metadata <- decode.optional_field("metadata", "", decode.string)
  decode.success(types.Contract(
    abi: abi,
    evm: evm,
    metadata: metadata
  ))
}

// Simplified ABI item decoder
fn abi_item_decoder() -> decode.Decoder(types.ABIType) {
  use item_type <- decode.field("type", decode.string)
  case item_type {
    "function" -> {
      use name <- decode.field("name", decode.string)
      use inputs <- decode.optional_field("inputs", [], decode.list(abi_parameter_decoder()))
      use outputs <- decode.optional_field("outputs", [], decode.list(abi_parameter_decoder()))
      use state_mutability <- decode.optional_field("stateMutability", "nonpayable", decode.string)
      decode.success(types.ABIFunction(name: name, inputs: inputs, outputs: outputs, state_mutability: state_mutability))
    }
    _ -> {
      use state_mutability <- decode.optional_field("stateMutability", "nonpayable", decode.string)
      decode.success(types.ABIFallback(state_mutability: state_mutability))
    }
  }
}

// Simplified ABI parameter decoder
fn abi_parameter_decoder() -> decode.Decoder(types.ABIParameter) {
  use name <- decode.optional_field("name", "", decode.string)
  use type_ <- decode.field("type", decode.string)
  use internal_type <- decode.optional_field("internalType", type_, decode.string)
  use indexed <- decode.optional_field("indexed", None, decode.optional(decode.bool))
  decode.success(types.ABIParameter(name: name, type_: type_, internal_type: internal_type, indexed: indexed))
}

// Simplified EVM decoder
fn evm_decoder() -> decode.Decoder(types.EVM) {
  use bytecode <- decode.field("bytecode", bytecode_decoder())
  use deployed_bytecode <- decode.optional_field("deployedBytecode", None, decode.optional(bytecode_decoder()))
  use gas_estimates <- decode.optional_field("gasEstimates", None, decode.optional(gas_estimates_decoder()))
  use method_identifiers <- decode.optional_field("methodIdentifiers", dict.new(), decode.dict(decode.string, decode.string))
  decode.success(types.EVM(
    bytecode: bytecode,
    deployed_bytecode: deployed_bytecode,
    gas_estimates: gas_estimates,
    method_identifiers: method_identifiers
  ))
}

// Bytecode decoder
fn bytecode_decoder() -> decode.Decoder(types.Bytecode) {
  use object <- decode.field("object", decode.string)
  use link_references <- decode.optional_field("linkReferences", dict.new(), decode.dict(decode.string, decode.list(link_reference_decoder())))
  use source_map <- decode.optional_field("sourceMap", None, decode.optional(decode.string))
  decode.success(types.Bytecode(
    object: object,
    link_references: link_references,
    source_map: source_map
  ))
}

// Link reference decoder
fn link_reference_decoder() -> decode.Decoder(types.LinkReference) {
  use start <- decode.field("start", decode.int)
  use length <- decode.field("length", decode.int)
  decode.success(types.LinkReference(start: start, length: length))
}

// Gas estimates decoder
fn gas_estimates_decoder() -> decode.Decoder(types.GasEstimates) {
  use creation <- decode.optional_field("creation", None, decode.optional(creation_gas_decoder()))
  use external <- decode.optional_field("external", dict.new(), decode.dict(decode.string, decode.string))
  decode.success(types.GasEstimates(creation: creation, external: external))
}

// Creation gas decoder
fn creation_gas_decoder() -> decode.Decoder(types.CreationGas) {
  use code_deposit_cost <- decode.field("codeDepositCost", decode.string)
  use execution_cost <- decode.field("executionCost", decode.string)
  use total_cost <- decode.field("totalCost", decode.string)
  decode.success(types.CreationGas(
    code_deposit_cost: code_deposit_cost,
    execution_cost: execution_cost,
    total_cost: total_cost
  ))
}

// Decoder for errors list
fn errors_decoder() -> decode.Decoder(List(types.CompilationError)) {
  decode.list(compilation_error_decoder())
}

// Decoder for compilation error
fn compilation_error_decoder() -> decode.Decoder(types.CompilationError) {
  use severity <- decode.field("severity", decode.string)
  use message <- decode.field("message", decode.string)
  use formatted_message <- decode.optional_field("formattedMessage", None, decode.optional(decode.string))
  decode.success(types.CompilationError(
    severity: severity,
    message: message,
    formatted_message: formatted_message,
    source_location: None, // TODO: Parse source location
    error_code: None
  ))
}