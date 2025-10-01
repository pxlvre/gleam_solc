import end_to_end_test
import gleeunit
import integration_test
import performance_test
import unit_test

pub fn main() -> Nil {
  gleeunit.main()
}

// Re-export basic tests
pub fn types_test() {
  unit_test.types_test()
}

pub fn error_types_test() {
  unit_test.error_types_test()
}

pub fn compilation_input_test() {
  unit_test.compilation_input_test()
}

// Integration tests - comprehensive scenarios
pub fn wrapper_creation_test() {
  integration_test.wrapper_creation_test()
}

pub fn simple_contract_input_test() {
  integration_test.simple_contract_input_test()
}

pub fn multiple_inheritance_input_test() {
  integration_test.multiple_inheritance_input_test()
}

pub fn error_handling_test() {
  integration_test.error_handling_test()
}

pub fn compilation_error_parsing_test() {
  integration_test.compilation_error_parsing_test()
}

pub fn abi_types_test() {
  integration_test.abi_types_test()
}

pub fn bytecode_structure_test() {
  integration_test.bytecode_structure_test()
}

pub fn evm_structure_test() {
  integration_test.evm_structure_test()
}

// End-to-end tests - complete workflow scenarios
pub fn complete_compilation_workflow_test() {
  end_to_end_test.complete_compilation_workflow_test()
}

pub fn expected_compilation_output_test() {
  end_to_end_test.expected_compilation_output_test()
}

pub fn compilation_error_scenarios_test() {
  end_to_end_test.compilation_error_scenarios_test()
}

pub fn download_load_workflow_test() {
  end_to_end_test.download_load_workflow_test()
}

// Performance benchmarks
pub fn type_construction_benchmark() {
  performance_test.type_construction_benchmark()
}

pub fn large_input_benchmark() {
  performance_test.large_input_benchmark()
}

pub fn multi_file_benchmark() {
  performance_test.multi_file_benchmark()
}

pub fn abi_construction_benchmark() {
  performance_test.abi_construction_benchmark()
}

pub fn error_handling_benchmark() {
  performance_test.error_handling_benchmark()
}

pub fn json_encoding_benchmark() {
  performance_test.json_encoding_benchmark()
}
