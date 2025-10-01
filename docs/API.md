# Gleam Solc API Documentation

A comprehensive Gleam library for compiling Solidity contracts, inspired by [deno-web3/solc](https://github.com/deno-web3/solc).

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Main Module (`solc`)](#main-module-solc)
  - [Types Module (`solc/types`)](#types-module-solctypes)
  - [Download Module (`solc/download`)](#download-module-solcdownload)
  - [Wrapper Module (`solc/wrapper`)](#wrapper-module-solcwrapper)
- [Type Definitions](#type-definitions)
- [Error Handling](#error-handling)
- [Examples](#examples)

## Overview

Gleam Solc provides type-safe bindings for the Solidity compiler, enabling compilation of Solidity contracts with full support for:

- **Multiple Inheritance**: Interfaces, abstract contracts, and implementation chains
- **Error Handling**: Comprehensive compilation error detection and reporting
- **Modern Solidity**: Full support for Solidity 0.8+ features
- **Type Safety**: Leveraging Gleam's type system for safer compilation
- **Cross-Platform**: JavaScript runtime support

## Installation

Add to your `gleam.toml`:

```toml
[dependencies]
gleam_solc = { git = "https://github.com/pxlvre/gleam_solc" }
```

## Quick Start

```gleam
import gleam/dict
import gleam/option.{Some}
import solc
import solc/types

pub fn main() {
  // 1. Load Solidity compiler
  let assert Ok(compiler) = solc.load_solc("./cache/solc-v0.8.19.js", Some("0.8.19"))
  
  // 2. Define your contract
  let source = "
pragma solidity ^0.8.0;
contract HelloWorld {
    string public message = \"Hello, World!\";
}
"
  
  // 3. Compile
  let assert Ok(output) = solc.compile_simple(compiler, "HelloWorld", source)
  
  // 4. Access compiled contract
  case output.contracts {
    Some(contracts) -> {
      // Use your compiled contract
      io.println("Compilation successful!")
    }
    None -> io.println("No contracts compiled")
  }
}
```

## API Reference

### Main Module (`solc`)

The main entry point for the Gleam Solc library.

#### `load_solc(path: String, version: Option(String)) -> Promise(Result(SolcWrapper, SolcError))`

Downloads and loads a Solidity compiler.

**Parameters:**
- `path`: Local file path to store/load the solc module
- `version`: Optional specific version to download (uses latest if None)

**Returns:** Promise resolving to a SolcWrapper or error

**Example:**
```gleam
import solc
import gleam/option.{Some, None}

// Load specific version
let assert Ok(solc_wrapper) = solc.load_solc("./solc-v0.8.19.js", Some("0.8.19"))

// Load latest version  
let assert Ok(solc_wrapper) = solc.load_solc("./solc-latest.js", None)
```

#### `compile_simple(solc: SolcWrapper, contract_name: String, source_code: String) -> Result(CompilationOutput, SolcError)`

Compiles a single Solidity contract with default settings.

**Parameters:**
- `solc`: Loaded SolcWrapper instance
- `contract_name`: Name identifier for the contract
- `source_code`: Solidity source code as string

**Returns:** CompilationOutput or error

**Example:**
```gleam
let source = "contract Simple { uint256 public value; }"
let assert Ok(output) = solc.compile_simple(solc_wrapper, "Simple", source)
```

#### `compile_multiple(solc: SolcWrapper, sources: Dict(String, String)) -> Result(CompilationOutput, SolcError)`

Compiles multiple Solidity files with dependency resolution.

**Parameters:**
- `solc`: Loaded SolcWrapper instance  
- `sources`: Dictionary mapping filename to source code

**Returns:** CompilationOutput or error

**Example:**
```gleam
import gleam/dict

let sources = dict.from_list([
  #("IERC20.sol", interface_source),
  #("ERC20.sol", implementation_source)
])
let assert Ok(output) = solc.compile_multiple(solc_wrapper, sources)
```

### Types Module (`solc/types`)

Core type definitions for Solidity compilation.

#### Key Types

**`SolcError`** - Comprehensive error handling
```gleam
pub type SolcError {
  DownloadError(String)      // Network/download failures
  CompilationFailed(String)  // Solidity compilation errors
  FFIError(String)          // JavaScript FFI errors
  InvalidInput(String)      // Invalid compilation input
  VersionNotFound(String)   // Requested version unavailable
}
```

**`CompilationInput`** - Input structure for compilation
```gleam
pub type CompilationInput {
  CompilationInput(
    language: String,                    // "Solidity"
    sources: Dict(String, Source),       // filename -> source mapping
    settings: CompilationSettings        // compiler settings
  )
}
```

**`CompilationOutput`** - Results from compilation
```gleam
pub type CompilationOutput {
  CompilationOutput(
    sources: Option(Dict(String, SourceInfo)),           // Source file info
    contracts: Option(Dict(String, Dict(String, Contract))), // Compiled contracts
    errors: Option(List(CompilationError))               // Compilation errors
  )
}
```

**`Contract`** - Compiled contract data
```gleam
pub type Contract {
  Contract(
    abi: List(ABIType),    // Contract ABI
    evm: EVM,              // EVM bytecode and metadata
    metadata: String       // Compiler metadata
  )
}
```

### Download Module (`solc/download`)

Handles downloading and managing Solidity compiler versions.

#### `download(path: String, version: Option(SolcVersion)) -> Promise(Result(SolcVersion, SolcError))`

Downloads a specific Solidity compiler version.

**Parameters:**
- `path`: Local path to save the compiler
- `version`: Optional version (uses latest if None)

**Returns:** Promise with downloaded version or error

#### `fetch_releases() -> Promise(Result(ReleaseInfo, SolcError))`

Fetches available Solidity compiler releases from the official repository.

**Returns:** Promise with release information or error

#### `solc_exists(path: String) -> Bool`

Checks if a Solidity compiler file exists at the given path.

**Parameters:**
- `path`: File path to check

**Returns:** Boolean indicating file existence

### Wrapper Module (`solc/wrapper`)

Low-level wrapper around loaded Solidity compiler modules.

#### `create_wrapper(soljson: SoljsonModule) -> Result(SolcWrapper, SolcError)`

Creates a wrapper around a loaded solc module.

#### `load_wrapper(path: String) -> Result(SolcWrapper, SolcError)`

Loads a Solidity compiler from file and creates a wrapper.

## Type Definitions

### ABI Types

The library provides comprehensive ABI type definitions:

```gleam
pub type ABIType {
  ABIFunction(
    name: String,
    inputs: List(ABIParameter),
    outputs: List(ABIParameter), 
    state_mutability: String
  )
  ABIEvent(
    name: String,
    inputs: List(ABIParameter),
    anonymous: Bool
  )
  ABIConstructor(
    inputs: List(ABIParameter),
    state_mutability: String
  )
  ABIFallback(state_mutability: String)
  ABIReceive(state_mutability: String)
}

pub type ABIParameter {
  ABIParameter(
    name: String,
    type_: String,
    internal_type: String,
    indexed: Option(Bool)
  )
}
```

### EVM Types

```gleam
pub type EVM {
  EVM(
    bytecode: Bytecode,
    deployed_bytecode: Option(Bytecode),
    gas_estimates: Option(GasEstimates),
    method_identifiers: Dict(String, String)
  )
}

pub type Bytecode {
  Bytecode(
    object: String,
    link_references: Dict(String, List(LinkReference)),
    source_map: Option(String)
  )
}
```

### Compilation Settings

```gleam
pub type CompilationSettings {
  CompilationSettings(
    output_selection: OutputSelection,
    optimizer: Option(OptimizerSettings),
    evm_version: Option(String),
    libraries: Option(Dict(String, String)),
    remappings: Option(List(String))
  )
}

pub type OptimizerSettings {
  OptimizerSettings(
    enabled: Bool,
    runs: Int
  )
}
```

## Error Handling

The library uses comprehensive error types for different failure scenarios:

```gleam
import solc

case solc.compile_simple(wrapper, "Test", source) {
  Ok(output) -> {
    // Handle successful compilation
    case output.errors {
      Some(errors) -> {
        // Check for warnings/errors in compilation
        errors
        |> list.each(fn(error) {
          case error.severity {
            "error" -> io.println("Error: " <> error.message)
            "warning" -> io.println("Warning: " <> error.message)
            _ -> Nil
          }
        })
      }
      None -> io.println("Clean compilation!")
    }
  }
  Error(solc_error) -> {
    case solc_error {
      types.CompilationFailed(msg) -> io.println("Compilation failed: " <> msg)
      types.InvalidInput(msg) -> io.println("Invalid input: " <> msg)
      types.FFIError(msg) -> io.println("FFI error: " <> msg)
      types.DownloadError(msg) -> io.println("Download error: " <> msg)
      types.VersionNotFound(msg) -> io.println("Version error: " <> msg)
    }
  }
}
```

## Examples

### Multiple Inheritance Compilation

```gleam
import gleam/dict
import solc

pub fn compile_inheritance_example() {
  let interface_source = "
pragma solidity ^0.8.0;
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}
"

  let abstract_source = "
pragma solidity ^0.8.0;
import \"./IERC20.sol\";
abstract contract ERC20Base is IERC20 {
    mapping(address => uint256) internal _balances;
}
"

  let implementation_source = "
pragma solidity ^0.8.0;
import \"./ERC20Base.sol\";
contract MyToken is ERC20Base {
    function transfer(address to, uint256 amount) external override returns (bool) {
        // Implementation
        return true;
    }
}
"

  let sources = dict.from_list([
    #("IERC20.sol", interface_source),
    #("ERC20Base.sol", abstract_source), 
    #("MyToken.sol", implementation_source)
  ])

  let assert Ok(solc_wrapper) = solc.load_solc("./solc.js", None)
  let assert Ok(output) = solc.compile_multiple(solc_wrapper, sources)
  
  // Access compiled contracts
  case output.contracts {
    Some(contracts) -> {
      case dict.get(contracts, "MyToken.sol") {
        Ok(file_contracts) -> {
          case dict.get(file_contracts, "MyToken") {
            Ok(contract) -> {
              io.println("MyToken compiled successfully!")
              io.println("ABI functions: " <> int.to_string(list.length(contract.abi)))
            }
            Error(_) -> io.println("MyToken not found")
          }
        }
        Error(_) -> io.println("File not found")
      }
    }
    None -> io.println("No contracts compiled")
  }
}
```

### Custom Compilation Settings

```gleam
import solc/types

pub fn custom_compilation_example() {
  let output_selection = types.OutputSelection(
    selections: dict.from_list([
      #("*", dict.from_list([
        #("*", [
          "abi", 
          "evm.bytecode", 
          "evm.deployedBytecode",
          "evm.gasEstimates",
          "evm.methodIdentifiers",
          "metadata",
          "storageLayout"
        ])
      ]))
    ])
  )
  
  let settings = types.CompilationSettings(
    output_selection: output_selection,
    optimizer: Some(types.OptimizerSettings(enabled: True, runs: 1000)),
    evm_version: Some("london"),
    libraries: None,
    remappings: Some([
      "@openzeppelin/contracts/=./node_modules/@openzeppelin/contracts/"
    ])
  )
  
  let input = types.CompilationInput(
    language: "Solidity",
    sources: sources,
    settings: settings
  )
  
  // Use custom input with wrapper
  case wrapper.compile_standard(solc_module, encode_input(input)) {
    Ok(output_json) -> {
      // Parse output
      parse_compilation_output(output_json)
    }
    Error(msg) -> Error(types.CompilationFailed(msg))
  }
}
```

---

This API documentation provides comprehensive coverage of the Gleam Solc library's functionality, types, and usage patterns.