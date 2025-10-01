import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/option.{type Option}

// Core types for Solidity compilation

pub type SolcVersion =
  String

pub type SolcError {
  DownloadError(String)
  CompilationFailed(String)
  FFIError(String)
  InvalidInput(String)
  VersionNotFound(String)
}

// Input types for compilation
pub type Source {
  Source(content: String)
}

pub type OutputSelection {
  OutputSelection(
    // File selection -> Contract selection -> Output types
    selections: Dict(String, Dict(String, List(String))),
  )
}

pub type OptimizerSettings {
  OptimizerSettings(enabled: Bool, runs: Int)
}

pub type CompilationSettings {
  CompilationSettings(
    output_selection: OutputSelection,
    optimizer: Option(OptimizerSettings),
    evm_version: Option(String),
    libraries: Option(Dict(String, String)),
    remappings: Option(List(String)),
  )
}

pub type CompilationInput {
  CompilationInput(
    language: String,
    // "Solidity"
    sources: Dict(String, Source),
    settings: CompilationSettings,
  )
}

// Output types for compilation results
pub type ABIType {
  ABIFunction(
    name: String,
    inputs: List(ABIParameter),
    outputs: List(ABIParameter),
    state_mutability: String,
  )
  ABIEvent(name: String, inputs: List(ABIParameter), anonymous: Bool)
  ABIConstructor(inputs: List(ABIParameter), state_mutability: String)
  ABIFallback(state_mutability: String)
  ABIReceive(state_mutability: String)
}

pub type ABIParameter {
  ABIParameter(
    name: String,
    type_: String,
    internal_type: String,
    indexed: Option(Bool),
  )
}

pub type LinkReference {
  LinkReference(start: Int, length: Int)
}

pub type Bytecode {
  Bytecode(
    object: String,
    link_references: Dict(String, List(LinkReference)),
    source_map: Option(String),
  )
}

pub type GasEstimates {
  GasEstimates(creation: Option(CreationGas), external: Dict(String, String))
}

pub type CreationGas {
  CreationGas(
    code_deposit_cost: String,
    execution_cost: String,
    total_cost: String,
  )
}

pub type EVM {
  EVM(
    bytecode: Bytecode,
    deployed_bytecode: Option(Bytecode),
    gas_estimates: Option(GasEstimates),
    method_identifiers: Dict(String, String),
  )
}

pub type Contract {
  Contract(abi: List(ABIType), evm: EVM, metadata: String)
}

pub type SourceInfo {
  SourceInfo(id: Int, ast: Option(Json))
}

pub type CompilationError {
  CompilationError(
    severity: String,
    // "error", "warning", "info"
    message: String,
    formatted_message: Option(String),
    source_location: Option(SourceLocation),
    error_code: Option(String),
  )
}

pub type SourceLocation {
  SourceLocation(file: String, start: Int, end: Int)
}

pub type CompilationOutput {
  CompilationOutput(
    sources: Option(Dict(String, SourceInfo)),
    contracts: Option(Dict(String, Dict(String, Contract))),
    errors: Option(List(CompilationError)),
  )
}

// Wrapper interface types
pub type SolcWrapper {
  SolcWrapper(
    version: fn() -> String,
    license: fn() -> String,
    compile: fn(String) -> Result(CompilationOutput, SolcError),
  )
}
