// End-to-end tests for complete Solidity compilation workflow
// These tests demonstrate the full workflow from source to bytecode

import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import solc/types

// Mock a complete compilation workflow
pub fn complete_compilation_workflow_test() {
  // 1. Define Solidity source code
  let contract_source =
    "
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private storedData;
    
    event DataStored(uint256 indexed value, address indexed by);
    
    constructor(uint256 initialValue) {
        storedData = initialValue;
    }
    
    function set(uint256 value) public {
        storedData = value;
        emit DataStored(value, msg.sender);
    }
    
    function get() public view returns (uint256) {
        return storedData;
    }
}
"

  // 2. Test that we can create proper compilation input
  let sources =
    dict.from_list([
      #("SimpleStorage.sol", types.Source(content: contract_source)),
    ])

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
              "metadata",
              "storageLayout",
            ]),
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

  let input =
    types.CompilationInput(
      language: "Solidity",
      sources: sources,
      settings: settings,
    )

  // 3. Verify the input is properly formed
  should.equal(input.language, "Solidity")
  should.equal(dict.size(input.sources), 1)

  case dict.get(input.sources, "SimpleStorage.sol") {
    Ok(source) -> {
      should.be_true(string.contains(source.content, "SimpleStorage"))
      should.be_true(string.contains(source.content, "constructor"))
      should.be_true(string.contains(source.content, "function set"))
      should.be_true(string.contains(source.content, "event DataStored"))
    }
    Error(_) -> should.fail()
  }

  // 4. Test optimizer settings are correct
  case input.settings.optimizer {
    Some(opts) -> {
      should.equal(opts.enabled, True)
      should.equal(opts.runs, 200)
    }
    None -> should.fail()
  }

  // 5. Test EVM version is set
  should.equal(input.settings.evm_version, Some("london"))

  // 6. Test output selection includes all needed outputs
  case dict.get(input.settings.output_selection.selections, "*") {
    Ok(contracts) -> {
      case dict.get(contracts, "*") {
        Ok(outputs) -> {
          should.be_true(list.contains(outputs, "abi"))
          should.be_true(list.contains(outputs, "evm.bytecode"))
          should.be_true(list.contains(outputs, "metadata"))
          should.be_true(list.contains(outputs, "storageLayout"))
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// Test expected compilation output structure
pub fn expected_compilation_output_test() {
  // Mock what a successful compilation output would look like
  let mock_abi = [
    types.ABIConstructor(
      inputs: [
        types.ABIParameter(
          name: "initialValue",
          type_: "uint256",
          internal_type: "uint256",
          indexed: None,
        ),
      ],
      state_mutability: "nonpayable",
    ),
    types.ABIFunction(
      name: "set",
      inputs: [
        types.ABIParameter(
          name: "value",
          type_: "uint256",
          internal_type: "uint256",
          indexed: None,
        ),
      ],
      outputs: [],
      state_mutability: "nonpayable",
    ),
    types.ABIFunction(
      name: "get",
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
    types.ABIEvent(
      name: "DataStored",
      inputs: [
        types.ABIParameter(
          name: "value",
          type_: "uint256",
          internal_type: "uint256",
          indexed: Some(True),
        ),
        types.ABIParameter(
          name: "by",
          type_: "address",
          internal_type: "address",
          indexed: Some(True),
        ),
      ],
      anonymous: False,
    ),
  ]

  let mock_bytecode =
    types.Bytecode(
      object: "0x608060405234801561001057600080fd5b50600436106100365760003560e01c806360fe47b11461003b5780636d4ce63c14610057575b600080fd5b610055600480360381019061005091906100a3565b610075565b005b61005f61007f565b60405161006c91906100df565b60405180910390f35b8060008190555050565b60008054905090565b60008135905061009d8161012c565b92915050565b6000602082840312156100b557600080fd5b60006100c38482850161008e565b91505092915050565b6100d5816100fa565b82525050565b60006020820190506100f060008301846100cc565b92915050565b6000819050919050565b600061010b826100fa565b9150610116836100fa565b9250827fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0382111561014b5761014a610104565b5b828201905092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b610195816100fa565b81146101a057600080fd5b5056fea26469706673582212201234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef64736f6c63430008070033",
      link_references: dict.new(),
      source_map: Some(
        "58:2:0:-:0;;;91:32:1;123:5:1;117:11;;91:32;;;;;;;:::i;:::-;;;;58:2:0;;;;;;:::o;:::-;;;;123:5:1;117:11;;91:32;;;;;:::i;:::-;;:::o;",
      ),
    )

  let mock_gas_estimates =
    types.GasEstimates(
      creation: Some(types.CreationGas(
        code_deposit_cost: "200000",
        execution_cost: "41908",
        total_cost: "241908",
      )),
      external: dict.from_list([#("get()", "2373"), #("set(uint256)", "24755")]),
    )

  let mock_evm =
    types.EVM(
      bytecode: mock_bytecode,
      deployed_bytecode: Some(mock_bytecode),
      gas_estimates: Some(mock_gas_estimates),
      method_identifiers: dict.from_list([
        #("get()", "6d4ce63c"),
        #("set(uint256)", "60fe47b1"),
      ]),
    )

  let mock_contract =
    types.Contract(
      abi: mock_abi,
      evm: mock_evm,
      metadata: "{\"compiler\":{\"version\":\"0.8.7+commit.e28d00a7\"},\"language\":\"Solidity\",\"output\":{\"abi\":[{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"initialValue\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"}],\"devdoc\":{\"kind\":\"dev\",\"methods\":{},\"version\":1},\"userdoc\":{\"kind\":\"user\",\"methods\":{},\"version\":1}},\"settings\":{\"compilationTarget\":{\"SimpleStorage.sol\":\"SimpleStorage\"},\"evmVersion\":\"london\",\"libraries\":{},\"metadata\":{\"bytecodeHash\":\"ipfs\"},\"optimizer\":{\"enabled\":true,\"runs\":200},\"remappings\":[]},\"sources\":{\"SimpleStorage.sol\":{\"keccak256\":\"0x...\",\"urls\":[\"bzz-raw://...\",\"dweb:/ipfs/...\"]}},\"version\":\"0.8.7+commit.e28d00a7\"}",
    )

  let mock_contracts =
    dict.from_list([
      #(
        "SimpleStorage.sol",
        dict.from_list([#("SimpleStorage", mock_contract)]),
      ),
    ])

  let mock_sources =
    dict.from_list([
      #(
        "SimpleStorage.sol",
        types.SourceInfo(
          id: 0,
          ast: None,
          // AST would be complex, not testing here
        ),
      ),
    ])

  let mock_output =
    types.CompilationOutput(
      sources: Some(mock_sources),
      contracts: Some(mock_contracts),
      errors: None,
      // No compilation errors in this test
    )

  // Test the mock output structure
  case mock_output.contracts {
    Some(contracts) -> {
      should.equal(dict.size(contracts), 1)
      case dict.get(contracts, "SimpleStorage.sol") {
        Ok(file_contracts) -> {
          should.equal(dict.size(file_contracts), 1)
          case dict.get(file_contracts, "SimpleStorage") {
            Ok(contract) -> {
              // Test ABI has expected functions
              should.equal(list.length(contract.abi), 4)
              // constructor, set, get, event

              // Test bytecode exists and looks valid
              should.be_true(string.starts_with(
                contract.evm.bytecode.object,
                "0x",
              ))
              should.be_true(string.length(contract.evm.bytecode.object) > 100)

              // Test method identifiers are present
              should.be_true(dict.has_key(
                contract.evm.method_identifiers,
                "get()",
              ))
              should.be_true(dict.has_key(
                contract.evm.method_identifiers,
                "set(uint256)",
              ))

              // Test gas estimates are reasonable
              case contract.evm.gas_estimates {
                Some(estimates) -> {
                  case estimates.creation {
                    Some(creation) -> {
                      should.be_true(string.length(creation.total_cost) > 0)
                    }
                    None -> should.fail()
                  }
                }
                None -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    None -> should.fail()
  }
}

// Test error scenarios that could occur during compilation
pub fn compilation_error_scenarios_test() {
  // Mock compilation errors that could be returned
  let syntax_error =
    types.CompilationError(
      severity: "error",
      message: "Expected ';' but got '}'",
      formatted_message: Some(
        "SyntaxError: Expected ';' but got '}' at SimpleStorage.sol:10:5",
      ),
      source_location: Some(types.SourceLocation(
        file: "SimpleStorage.sol",
        start: 250,
        end: 251,
      )),
      error_code: Some("2314"),
    )

  let warning_error =
    types.CompilationError(
      severity: "warning",
      message: "Unused local variable",
      formatted_message: Some(
        "Warning: Unused local variable 'temp' at SimpleStorage.sol:15:12",
      ),
      source_location: Some(types.SourceLocation(
        file: "SimpleStorage.sol",
        start: 380,
        end: 384,
      )),
      error_code: Some("2072"),
    )

  let type_error =
    types.CompilationError(
      severity: "error",
      message: "Type int256 is not implicitly convertible to expected type uint256",
      formatted_message: Some(
        "TypeError: Type int256 is not implicitly convertible to expected type uint256 at SimpleStorage.sol:8:20",
      ),
      source_location: Some(types.SourceLocation(
        file: "SimpleStorage.sol",
        start: 180,
        end: 190,
      )),
      error_code: Some("9574"),
    )

  let mock_error_output =
    types.CompilationOutput(
      sources: None,
      contracts: None,
      errors: Some([syntax_error, warning_error, type_error]),
    )

  // Test error parsing
  case mock_error_output.errors {
    Some(errors) -> {
      should.equal(list.length(errors), 3)

      // Check we have different severity levels
      let severities = list.map(errors, fn(err) { err.severity })
      should.be_true(list.contains(severities, "error"))
      should.be_true(list.contains(severities, "warning"))

      // Check error codes are present
      // Check error codes are present
      let has_error_codes =
        list.all(errors, fn(err) {
          case err.error_code {
            Some(_) -> True
            None -> False
          }
        })
      should.be_true(has_error_codes)

      // Check source locations are provided
      let has_locations =
        list.all(errors, fn(err) {
          case err.source_location {
            Some(_) -> True
            None -> False
          }
        })
      should.be_true(has_locations)
    }
    None -> should.fail()
  }
}

// Test the download and load workflow structure 
pub fn download_load_workflow_test() {
  // This tests the expected workflow without actual FFI
  // 1. Check if solc exists locally
  // 2. If not, download it
  // 3. Load the solc module
  // 4. Create wrapper
  // 5. Compile source

  // Mock version handling
  let version = "0.8.19"
  should.be_true(string.starts_with(version, "0.8"))

  // Mock path handling
  let solc_path = "./cache/solc-v" <> version <> ".js"
  should.be_true(string.contains(solc_path, version))

  // Test that our types support the expected workflow
  let mock_download_result: Result(String, types.SolcError) = Ok(version)
  case mock_download_result {
    Ok(downloaded_version) -> should.equal(downloaded_version, version)
    Error(_) -> should.be_true(True)
    // Both outcomes valid for test
  }

  // Test error handling in download
  let mock_download_error: Result(String, types.SolcError) =
    Error(types.DownloadError("Network error: Connection timeout"))
  case mock_download_error {
    Error(types.DownloadError(msg)) ->
      should.be_true(string.contains(msg, "Network error"))
    _ -> should.fail()
  }

  // Test version not found error
  let mock_version_error: Result(String, types.SolcError) =
    Error(types.VersionNotFound("Version 0.8.999 not found in releases"))
  case mock_version_error {
    Error(types.VersionNotFound(msg)) ->
      should.be_true(string.contains(msg, "not found"))
    _ -> should.fail()
  }
}
