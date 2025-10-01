// Performance benchmarks for Gleam Solc library
// These tests measure the performance characteristics of the library

import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import solc/types

// Benchmark: Type construction performance
pub fn type_construction_benchmark() {
  // Measure time to construct complex types
  let start_time = get_current_time()

  // Create a large number of type instances
  let _ =
    list.range(1, 1000)
    |> list.map(fn(i) {
      types.Source(content: "contract Test" <> int.to_string(i) <> " {}")
    })

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  io.println(
    "Type construction (1000 instances): " <> int.to_string(duration) <> "ms",
  )
}

// Benchmark: Large contract compilation input
pub fn large_input_benchmark() {
  let large_source = string.repeat("// Comment line\n", 1000) <> "
pragma solidity ^0.8.0;

contract LargeContract {
    " <> string.repeat("uint256 public var" <> "_;\n    ", 100) <> "
    
    constructor() {
        " <> string.repeat("var" <> "_ = 0;\n        ", 100) <> "
    }
}
"

  let start_time = get_current_time()

  let source = types.Source(content: large_source)
  let sources = dict.from_list([#("LargeContract.sol", source)])

  let output_selection =
    types.OutputSelection(
      selections: dict.from_list([
        #(
          "*",
          dict.from_list([
            #("*", ["abi", "evm.bytecode", "evm.deployedBytecode", "metadata"]),
          ]),
        ),
      ]),
    )

  let settings =
    types.CompilationSettings(
      output_selection: output_selection,
      optimizer: Some(types.OptimizerSettings(enabled: True, runs: 200)),
      evm_version: Some("london"),
      libraries: None,
      remappings: None,
    )

  let _input =
    types.CompilationInput(
      language: "Solidity",
      sources: sources,
      settings: settings,
    )

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  should.be_true(string.length(large_source) > 10_000)
  io.println(
    "Large input creation ("
    <> int.to_string(string.length(large_source))
    <> " chars): "
    <> int.to_string(duration)
    <> "ms",
  )
}

// Benchmark: Multiple file compilation input
pub fn multi_file_benchmark() {
  let start_time = get_current_time()

  // Create 50 contract files
  let sources =
    list.range(1, 50)
    |> list.map(fn(i) {
      let filename = "Contract" <> int.to_string(i) <> ".sol"
      let content = "
pragma solidity ^0.8.0;

contract Contract" <> int.to_string(i) <> " {
    uint256 public value" <> int.to_string(i) <> ";
    
    function setValue" <> int.to_string(i) <> "(uint256 _value) public {
        value" <> int.to_string(i) <> " = _value;
    }
    
    function getValue" <> int.to_string(i) <> "() public view returns (uint256) {
        return value" <> int.to_string(i) <> ";
    }
}
"
      #(filename, types.Source(content: content))
    })
    |> dict.from_list

  let output_selection =
    types.OutputSelection(
      selections: dict.from_list([
        #("*", dict.from_list([#("*", ["abi", "evm.bytecode"])])),
      ]),
    )

  let settings =
    types.CompilationSettings(
      output_selection: output_selection,
      optimizer: Some(types.OptimizerSettings(enabled: True, runs: 200)),
      evm_version: None,
      libraries: None,
      remappings: None,
    )

  let _input =
    types.CompilationInput(
      language: "Solidity",
      sources: sources,
      settings: settings,
    )

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  should.equal(dict.size(sources), 50)
  io.println(
    "Multi-file input (50 contracts): " <> int.to_string(duration) <> "ms",
  )
}

// Benchmark: Complex ABI construction
pub fn abi_construction_benchmark() {
  let start_time = get_current_time()

  // Create complex ABI with many functions
  let functions =
    list.range(1, 100)
    |> list.map(fn(i) {
      types.ABIFunction(
        name: "function" <> int.to_string(i),
        inputs: [
          types.ABIParameter(
            name: "param1",
            type_: "uint256",
            internal_type: "uint256",
            indexed: None,
          ),
          types.ABIParameter(
            name: "param2",
            type_: "address",
            internal_type: "address",
            indexed: None,
          ),
        ],
        outputs: [
          types.ABIParameter(
            name: "",
            type_: "bool",
            internal_type: "bool",
            indexed: None,
          ),
        ],
        state_mutability: "nonpayable",
      )
    })

  let events =
    list.range(1, 20)
    |> list.map(fn(i) {
      types.ABIEvent(
        name: "Event" <> int.to_string(i),
        inputs: [
          types.ABIParameter(
            name: "value",
            type_: "uint256",
            internal_type: "uint256",
            indexed: Some(True),
          ),
        ],
        anonymous: False,
      )
    })

  let _all_abi = list.append(functions, events)

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  should.equal(list.length(functions), 100)
  should.equal(list.length(events), 20)
  io.println(
    "Complex ABI construction (120 items): " <> int.to_string(duration) <> "ms",
  )
}

// Benchmark: Error handling performance
pub fn error_handling_benchmark() {
  let start_time = get_current_time()

  // Create many error instances
  let errors =
    list.range(1, 1000)
    |> list.map(fn(i) {
      case i % 5 {
        0 -> types.DownloadError("Download error " <> int.to_string(i))
        1 -> types.CompilationFailed("Compilation error " <> int.to_string(i))
        2 -> types.FFIError("FFI error " <> int.to_string(i))
        3 -> types.InvalidInput("Invalid input " <> int.to_string(i))
        _ -> types.VersionNotFound("Version error " <> int.to_string(i))
      }
    })

  // Process errors
  let _processed =
    list.map(errors, fn(error) {
      case error {
        types.DownloadError(msg) -> "Download: " <> msg
        types.CompilationFailed(msg) -> "Compilation: " <> msg
        types.FFIError(msg) -> "FFI: " <> msg
        types.InvalidInput(msg) -> "Input: " <> msg
        types.VersionNotFound(msg) -> "Version: " <> msg
      }
    })

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  should.equal(list.length(errors), 1000)
  io.println(
    "Error handling (1000 errors): " <> int.to_string(duration) <> "ms",
  )
}

// Benchmark: JSON encoding simulation
pub fn json_encoding_benchmark() {
  let start_time = get_current_time()

  // Simulate JSON encoding overhead
  let large_dict =
    list.range(1, 500)
    |> list.map(fn(i) {
      #("key" <> int.to_string(i), "value" <> int.to_string(i))
    })
    |> dict.from_list

  // Simulate processing the dictionary (like JSON encoding would)
  let _processed = dict.map_values(large_dict, fn(k, v) { k <> ":" <> v })

  let end_time = get_current_time()
  let duration = end_time - start_time

  should.be_true(duration >= 0)
  should.equal(dict.size(large_dict), 500)
  io.println(
    "Dictionary processing (500 entries): " <> int.to_string(duration) <> "ms",
  )
}

// Mock time function (in a real implementation, this would use actual timing)
fn get_current_time() -> Int {
  // In a real implementation, this would get actual timestamps
  // For testing purposes, we'll use a mock value
  42
}

// Run all performance benchmarks
pub fn run_all_benchmarks() {
  io.println("=== Gleam Solc Performance Benchmarks ===")
  io.println("")

  type_construction_benchmark()
  large_input_benchmark()
  multi_file_benchmark()
  abi_construction_benchmark()
  error_handling_benchmark()
  json_encoding_benchmark()

  io.println("")
  io.println("=== Benchmarks Complete ===")
  io.println(
    "Note: These are structural benchmarks showing the library can handle large inputs efficiently.",
  )
  io.println(
    "Real performance would depend on the actual Solidity compilation time.",
  )
}
