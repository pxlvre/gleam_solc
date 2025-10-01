import gleeunit
import basic_test
import integration_test

pub fn main() -> Nil {
  gleeunit.main()
}

// Re-export basic tests
pub fn error_types_test() {
  basic_test.error_types_test()
}

pub fn compilation_input_test() {
  basic_test.compilation_input_test()
}

pub fn compilation_output_test() {
  basic_test.compilation_output_test()
}

pub fn compilation_error_test() {
  basic_test.compilation_error_test()
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
