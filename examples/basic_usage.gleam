// Basic usage examples for Gleam Solc library
// This module demonstrates common use cases and patterns

import gleam/dict
import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import solc
import solc/types

// Example 1: Compile a simple contract
pub fn simple_contract_example() {
  let source =
    "
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private value;
    
    event ValueChanged(uint256 newValue);
    
    function setValue(uint256 _value) public {
        value = _value;
        emit ValueChanged(_value);
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}
"

  // This would be the actual usage pattern:
  // use load_result <- promise.try_await(solc.load_solc("./cache/solc-v0.8.19.js", Some("0.8.19")))
  // case load_result {
  //   Ok(solc_wrapper) -> {
  //     case solc.compile_simple(solc_wrapper, "SimpleStorage", source) {
  //       Ok(output) -> handle_compilation_success(output)
  //       Error(err) -> handle_compilation_error(err)
  //     }
  //   }
  //   Error(err) -> handle_load_error(err)
  // }

  // For this example, we'll demonstrate the expected structure
  io.println("Simple contract compilation example")
  io.println("Source length: " <> int.to_string(string.length(source)))
  io.println("Expected contract: SimpleStorage")
}

// Example 2: Multiple inheritance with interfaces and abstract contracts
pub fn inheritance_example() {
  let interface_source =
    "
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
"

  let abstract_source =
    "
pragma solidity ^0.8.0;

import \"./IOwnable.sol\";

abstract contract Ownable is IOwnable {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    function owner() public view override returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, \"Ownable: caller is not the owner\");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), \"Ownable: new owner is the zero address\");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
"

  let implementation_source =
    "
pragma solidity ^0.8.0;

import \"./Ownable.sol\";

contract MyContract is Ownable {
    string public name;
    uint256 public value;
    
    constructor(string memory _name) {
        name = _name;
        value = 0;
    }
    
    function setValue(uint256 _value) external onlyOwner {
        value = _value;
    }
    
    function emergencyStop() external onlyOwner {
        // Emergency functionality
        value = 0;
    }
}
"

  let sources =
    dict.from_list([
      #("IOwnable.sol", interface_source),
      #("Ownable.sol", abstract_source),
      #("MyContract.sol", implementation_source),
    ])

  // Example compilation workflow
  io.println("Multiple inheritance example")
  io.println("Files to compile: " <> int.to_string(dict.size(sources)))

  dict.each(sources, fn(filename, source) {
    io.println(
      "- "
      <> filename
      <> " ("
      <> int.to_string(string.length(source))
      <> " chars)",
    )
  })
}

// Example 3: Custom compilation settings
pub fn custom_settings_example() {
  let source =
    "
pragma solidity ^0.8.0;

contract OptimizedContract {
    mapping(address => uint256) private balances;
    uint256 private totalSupply;
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, \"Insufficient balance\");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}
"

  // Create custom output selection for detailed output
  let output_selection =
    types.OutputSelection(
      selections: dict.from_list([
        #(
          "*",
          dict.from_list([
            #("*", [
              "abi",
              "evm.bytecode",
              "evm.deployedBytecode",
              "evm.gasEstimates",
              "evm.methodIdentifiers",
              "metadata",
              "storageLayout",
              "devdoc",
              "userdoc",
            ]),
          ]),
        ),
      ]),
    )

  // Configure optimizer for high-frequency functions
  let optimizer =
    types.OptimizerSettings(
      enabled: True,
      runs: 1_000_000,
      // Optimize for many function calls
    )

  let settings =
    types.CompilationSettings(
      output_selection: output_selection,
      optimizer: Some(optimizer),
      evm_version: Some("london"),
      // Use London hard fork features
      libraries: None,
      remappings: None,
    )

  let input =
    types.CompilationInput(
      language: "Solidity",
      sources: dict.from_list([
        #("OptimizedContract.sol", types.Source(content: source)),
      ]),
      settings: settings,
    )

  io.println("Custom compilation settings example")
  io.println("Optimizer runs: " <> int.to_string(optimizer.runs))
  io.println("EVM version: london")
  io.println(
    "Output selections: "
    <> int.to_string(
      list.length([
        "abi",
        "evm.bytecode",
        "evm.deployedBytecode",
        "evm.gasEstimates",
        "evm.methodIdentifiers",
        "metadata",
        "storageLayout",
        "devdoc",
        "userdoc",
      ]),
    ),
  )
}

// Example 4: Error handling patterns
pub fn error_handling_example() {
  let invalid_source =
    "
contract InvalidSyntax {
    uint256 public value
    // Missing semicolon above
    
    function setValue(uint256 _value) public {
        value = _value
        // Missing semicolon above
    }
}
"

  // Demonstrate different error types and handling
  io.println("Error handling examples:")

  // 1. Compilation errors
  let compilation_error =
    types.CompilationError(
      severity: "error",
      message: "Expected ';' but got '}'",
      formatted_message: Some(
        "ParserError: Expected ';' but got '}' at InvalidSyntax.sol:3:21",
      ),
      source_location: Some(types.SourceLocation(
        file: "InvalidSyntax.sol",
        start: 65,
        end: 66,
      )),
      error_code: Some("2314"),
    )

  io.println("1. Syntax Error:")
  io.println("   " <> compilation_error.message)
  case compilation_error.formatted_message {
    Some(formatted) -> io.println("   " <> formatted)
    None -> Nil
  }

  // 2. Version errors
  let version_error =
    types.VersionNotFound("Version 0.8.999 not found in releases")
  io.println("2. Version Error: " <> get_error_message(version_error))

  // 3. Download errors
  let download_error =
    types.DownloadError("Failed to download: Network timeout")
  io.println("3. Download Error: " <> get_error_message(download_error))

  // 4. FFI errors
  let ffi_error = types.FFIError("Invalid solc module: Module not found")
  io.println("4. FFI Error: " <> get_error_message(ffi_error))
}

// Helper function to extract error messages
fn get_error_message(error: types.SolcError) -> String {
  case error {
    types.DownloadError(msg) -> msg
    types.CompilationFailed(msg) -> msg
    types.FFIError(msg) -> msg
    types.InvalidInput(msg) -> msg
    types.VersionNotFound(msg) -> msg
  }
}

// Example 5: Working with compilation output
pub fn output_analysis_example() {
  // Mock a successful compilation output
  let mock_abi = [
    types.ABIFunction(
      name: "setValue",
      inputs: [
        types.ABIParameter(
          name: "_value",
          type_: "uint256",
          internal_type: "uint256",
          indexed: None,
        ),
      ],
      outputs: [],
      state_mutability: "nonpayable",
    ),
    types.ABIFunction(
      name: "getValue",
      inputs: [],
      outputs: [
        types.ABIParameter(
          name: "",
          type_: "uint256",
          internal_type: "uint256",
          indexed: None,
        ),
      ],
      state_mutability: "view",
    ),
  ]

  let mock_bytecode =
    types.Bytecode(
      object: "0x608060405234801561001057600080fd5b5060043610610048760003560e01c806320965255146100...",
      link_references: dict.new(),
      source_map: Some(
        "1:2:0:-:0;;;8:1:-1;5:2;;;30:1;27;20:12;5:2;1:2:0;;;;;;;",
      ),
    )

  let mock_gas =
    types.GasEstimates(
      creation: Some(types.CreationGas(
        code_deposit_cost: "200000",
        execution_cost: "41908",
        total_cost: "241908",
      )),
      external: dict.from_list([
        #("getValue()", "2373"),
        #("setValue(uint256)", "24755"),
      ]),
    )

  let mock_evm =
    types.EVM(
      bytecode: mock_bytecode,
      deployed_bytecode: Some(mock_bytecode),
      gas_estimates: Some(mock_gas),
      method_identifiers: dict.from_list([
        #("getValue()", "20965255"),
        #("setValue(uint256)", "55241077"),
      ]),
    )

  let mock_contract =
    types.Contract(
      abi: mock_abi,
      evm: mock_evm,
      metadata: "{\"compiler\":{\"version\":\"0.8.19\"}}",
    )

  // Analyze the compilation output
  io.println("Compilation output analysis:")
  io.println("ABI functions: " <> int.to_string(list.length(mock_contract.abi)))
  io.println(
    "Bytecode size: "
    <> int.to_string(string.length(mock_contract.evm.bytecode.object)),
  )

  // Analyze gas estimates
  case mock_contract.evm.gas_estimates {
    Some(estimates) -> {
      case estimates.creation {
        Some(creation) -> {
          io.println("Deployment cost: " <> creation.total_cost <> " gas")
        }
        None -> Nil
      }

      io.println("Function gas costs:")
      dict.each(estimates.external, fn(method, cost) {
        io.println("  " <> method <> ": " <> cost <> " gas")
      })
    }
    None -> io.println("No gas estimates available")
  }

  // Analyze method identifiers
  io.println("Method identifiers:")
  dict.each(mock_contract.evm.method_identifiers, fn(method, id) {
    io.println("  " <> method <> ": 0x" <> id)
  })
}

// Example 6: Promise-based workflow
pub fn async_workflow_example() {
  // This demonstrates the async pattern for real usage

  // Step 1: Download and load compiler
  // let download_promise = solc.load_solc("./cache/solc-v0.8.19.js", Some("0.8.19"))

  // Step 2: Compile when ready
  // use solc_wrapper <- promise.try_await(download_promise)
  // case solc_wrapper {
  //   Ok(wrapper) -> {
  //     let source = "contract Test { uint256 public value; }"
  //     case solc.compile_simple(wrapper, "Test", source) {
  //       Ok(output) -> {
  //         io.println("Compilation successful!")
  //         promise.resolve(Ok(output))
  //       }
  //       Error(err) -> {
  //         io.println("Compilation failed: " <> get_error_message(err))
  //         promise.resolve(Error(err))
  //       }
  //     }
  //   }
  //   Error(err) -> {
  //     io.println("Failed to load solc: " <> get_error_message(err)) 
  //     promise.resolve(Error(err))
  //   }
  // }

  io.println("Async workflow pattern demonstrated")
  io.println("Steps: download -> load -> compile -> analyze")
}

// Main function to run all examples
pub fn run_examples() {
  io.println("=== Gleam Solc Usage Examples ===")
  io.println("")

  simple_contract_example()
  io.println("")

  inheritance_example()
  io.println("")

  custom_settings_example()
  io.println("")

  error_handling_example()
  io.println("")

  output_analysis_example()
  io.println("")

  async_workflow_example()
  io.println("")

  io.println("=== Examples Complete ===")
}
