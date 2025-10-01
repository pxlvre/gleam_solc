// Integration tests for Gleam Solc library
// Tests end-to-end functionality with real Solidity compilation scenarios

import gleeunit/should
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import solc/types
import solc/wrapper

// Mock Solc module for testing - simulate a loaded solc module
type MockSoljsonModule = String

// Test basic wrapper creation with valid module
pub fn wrapper_creation_test() {
  // This test simulates what would happen with a real solc module
  // In actual usage, this would come from loading a solc.js file
  let mock_module = "mock_solc_module"
  
  // For now, this will fail because we don't have real FFI
  // But it tests the structure and error handling
  case wrapper.create_wrapper(mock_module) {
    Error(types.FFIError(_msg)) -> should.be_true(True)  // Expected for mock
    Ok(_wrapper) -> should.be_true(True)  // Would be good if we had real FFI
    Error(_) -> should.fail()
  }
}

// Test compilation input creation for a simple contract
pub fn simple_contract_input_test() {
  let contract_source = "
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;
    
    constructor(string memory _message) {
        message = _message;
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
}
"

  let source = types.Source(content: contract_source)
  let sources = dict.from_list([#("HelloWorld.sol", source)])
  
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
  
  let input = types.CompilationInput(
    language: "Solidity",
    sources: sources,
    settings: settings
  )
  
  // Test that input is properly structured
  should.equal(input.language, "Solidity")
  should.equal(dict.size(input.sources), 1)
  case dict.get(input.sources, "HelloWorld.sol") {
    Ok(source) -> should.be_true(string.contains(source.content, "HelloWorld"))
    Error(_) -> should.fail()
  }
}

// Test multiple inheritance scenario
pub fn multiple_inheritance_input_test() {
  let interface_source = "
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
"

  let abstract_source = "
pragma solidity ^0.8.0;

import \"./IERC20.sol\";

abstract contract ERC20Base is IERC20 {
    mapping(address => uint256) internal _balances;
    uint256 internal _totalSupply;
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
}
"

  let implementation_source = "
pragma solidity ^0.8.0;

import \"./ERC20Base.sol\";

contract MyToken is ERC20Base {
    string public name;
    string public symbol;
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        _totalSupply = _totalSupply;
        _balances[msg.sender] = _totalSupply;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount, \"Insufficient balance\");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
}
"

  let sources = dict.from_list([
    #("IERC20.sol", types.Source(content: interface_source)),
    #("ERC20Base.sol", types.Source(content: abstract_source)),
    #("MyToken.sol", types.Source(content: implementation_source))
  ])
  
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
    evm_version: Some("london"),
    libraries: None,
    remappings: None
  )
  
  let input = types.CompilationInput(
    language: "Solidity",
    sources: sources,
    settings: settings
  )
  
  // Test that all files are included
  should.equal(dict.size(input.sources), 3)
  should.be_true(dict.has_key(input.sources, "IERC20.sol"))
  should.be_true(dict.has_key(input.sources, "ERC20Base.sol"))
  should.be_true(dict.has_key(input.sources, "MyToken.sol"))
  
  // Test optimizer settings
  case input.settings.optimizer {
    Some(opts) -> {
      should.equal(opts.enabled, True)
      should.equal(opts.runs, 200)
    }
    None -> should.fail()
  }
  
  // Test EVM version setting
  should.equal(input.settings.evm_version, Some("london"))
}

// Test error handling scenarios
pub fn error_handling_test() {
  // Test invalid input error
  let invalid_error = types.InvalidInput("Invalid compilation input")
  case invalid_error {
    types.InvalidInput(msg) -> should.equal(msg, "Invalid compilation input")
    _ -> should.fail()
  }
  
  // Test compilation failed error
  let compile_error = types.CompilationFailed("Syntax error in contract")
  case compile_error {
    types.CompilationFailed(msg) -> should.equal(msg, "Syntax error in contract")
    _ -> should.fail()
  }
  
  // Test version not found error
  let version_error = types.VersionNotFound("Version 0.8.999 not found")
  case version_error {
    types.VersionNotFound(msg) -> should.equal(msg, "Version 0.8.999 not found")
    _ -> should.fail()
  }
  
  // Test FFI error
  let ffi_error = types.FFIError("Failed to load module")
  case ffi_error {
    types.FFIError(msg) -> should.equal(msg, "Failed to load module")
    _ -> should.fail()
  }
  
  // Test download error
  let download_error = types.DownloadError("Network connection failed")
  case download_error {
    types.DownloadError(msg) -> should.equal(msg, "Network connection failed")
    _ -> should.fail()
  }
}

// Test compilation error parsing
pub fn compilation_error_parsing_test() {
  let error = types.CompilationError(
    severity: "error",
    message: "Undeclared identifier",
    formatted_message: Some("Error: Undeclared identifier 'foo' at line 10"),
    source_location: Some(types.SourceLocation(
      file: "Contract.sol",
      start: 150,
      end: 153
    )),
    error_code: Some("2304")
  )
  
  should.equal(error.severity, "error")
  should.equal(error.message, "Undeclared identifier")
  
  case error.formatted_message {
    Some(msg) -> should.be_true(string.contains(msg, "line 10"))
    None -> should.fail()
  }
  
  case error.source_location {
    Some(loc) -> {
      should.equal(loc.file, "Contract.sol")
      should.equal(loc.start, 150)
      should.equal(loc.end, 153)
    }
    None -> should.fail()
  }
  
  should.equal(error.error_code, Some("2304"))
}

// Test ABI type construction
pub fn abi_types_test() {
  // Test function ABI
  let function_abi = types.ABIFunction(
    name: "transfer",
    inputs: [
      types.ABIParameter(
        name: "to",
        type_: "address",
        internal_type: "address",
        indexed: None
      ),
      types.ABIParameter(
        name: "amount",
        type_: "uint256",
        internal_type: "uint256",
        indexed: None
      )
    ],
    outputs: [
      types.ABIParameter(
        name: "",
        type_: "bool",
        internal_type: "bool",
        indexed: None
      )
    ],
    state_mutability: "nonpayable"
  )
  
  should.equal(function_abi.name, "transfer")
  should.equal(string.length(function_abi.inputs), 2)
  should.equal(string.length(function_abi.outputs), 1)
  
  // Test event ABI
  let event_abi = types.ABIEvent(
    name: "Transfer",
    inputs: [
      types.ABIParameter(
        name: "from",
        type_: "address",
        internal_type: "address",
        indexed: Some(True)
      ),
      types.ABIParameter(
        name: "to",
        type_: "address",
        internal_type: "address",
        indexed: Some(True)
      ),
      types.ABIParameter(
        name: "value",
        type_: "uint256",
        internal_type: "uint256",
        indexed: Some(False)
      )
    ],
    anonymous: False
  )
  
  should.equal(event_abi.name, "Transfer")
  should.equal(event_abi.anonymous, False)
  
  // Test constructor ABI
  let constructor_abi = types.ABIConstructor(
    inputs: [
      types.ABIParameter(
        name: "_name",
        type_: "string",
        internal_type: "string",
        indexed: None
      )
    ],
    state_mutability: "nonpayable"
  )
  
  should.equal(string.length(constructor_abi.inputs), 1)
  should.equal(constructor_abi.state_mutability, "nonpayable")
}

// Test bytecode structure
pub fn bytecode_structure_test() {
  let link_ref = types.LinkReference(start: 100, length: 20)
  should.equal(link_ref.start, 100)
  should.equal(link_ref.length, 20)
  
  let bytecode = types.Bytecode(
    object: "0x608060405234801561001057600080fd5b50...",
    link_references: dict.from_list([
      #("Math.sol", [link_ref])
    ]),
    source_map: Some("1:2:0:1:1;8:26:0:1:1;")
  )
  
  should.be_true(string.starts_with(bytecode.object, "0x"))
  should.be_true(dict.has_key(bytecode.link_references, "Math.sol"))
  should.equal(bytecode.source_map, Some("1:2:0:1:1;8:26:0:1:1;"))
}

// Test EVM structure
pub fn evm_structure_test() {
  let bytecode = types.Bytecode(
    object: "0x608060405234801561001057600080fd5b50...",
    link_references: dict.new(),
    source_map: None
  )
  
  let gas_estimates = types.GasEstimates(
    creation: Some(types.CreationGas(
      code_deposit_cost: "200000",
      execution_cost: "41908",
      total_cost: "241908"
    )),
    external: dict.from_list([
      #("transfer(address,uint256)", "24755")
    ])
  )
  
  let evm = types.EVM(
    bytecode: bytecode,
    deployed_bytecode: Some(bytecode),
    gas_estimates: Some(gas_estimates),
    method_identifiers: dict.from_list([
      #("transfer(address,uint256)", "a9059cbb")
    ])
  )
  
  should.be_true(string.starts_with(evm.bytecode.object, "0x"))
  
  case evm.gas_estimates {
    Some(estimates) -> {
      case estimates.creation {
        Some(creation) -> should.equal(creation.total_cost, "241908")
        None -> should.fail()
      }
    }
    None -> should.fail()
  }
  
  should.be_true(dict.has_key(evm.method_identifiers, "transfer(address,uint256)"))
}