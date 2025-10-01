# Gleam Solc

A Gleam library for compiling Solidity contracts, providing type-safe bindings for the Solidity compiler [solc](https://github.com/argotorg/solc-bin) with full support for modern Solidity features.

[![Tests](https://img.shields.io/badge/tests-30%20passing-green)](./test/)
[![Gleam](https://img.shields.io/badge/gleam-1.12.0-purple)](https://gleam.run/)
[![JavaScript](https://img.shields.io/badge/target-javascript-yellow)](https://nodejs.org/)

## 🎯 Features

- **Type-Safe Compilation**: Leveraging Gleam's type system for safer Solidity compilation
- **Multiple Inheritance Support**: Full support for interfaces, abstract contracts, and implementation chains
- **Comprehensive Error Handling**: Detailed compilation error detection and reporting
- **Modern Solidity**: Support for Solidity 0.8+ with latest language features
- **Promise-Based API**: Async operations using JavaScript promises
- **Version Management**: Automatic downloading and caching of Solidity compiler versions

## 🚀 Quick Start

Add to your `gleam.toml`:

```toml
[dependencies]
solc = { git = "https://github.com/pxlvre/gleam_solc" }
```

Basic usage:

```gleam
import gleam/option.{Some}
import solc

pub fn main() {
  // Load Solidity compiler
  use solc_wrapper <- promise.try_await(solc.load_solc("./solc-v0.8.19.js", Some("0.8.19")))
  
  // Compile a simple contract
  let source = "
pragma solidity ^0.8.0;
contract HelloWorld {
    string public message = \"Hello, World!\";
}
"
  
  case solc.compile_simple(solc_wrapper, "HelloWorld", source) {
    Ok(output) -> io.println("Compilation successful!")
    Error(err) -> io.println("Compilation failed")
  }
}
```

## 📖 Documentation

- **[API Documentation](./docs/API.md)** - Comprehensive API reference
- **[Usage Examples](./examples/basic_usage.gleam)** - Common patterns and use cases
- **[Type Definitions](./src/solc/types.gleam)** - Complete type system reference

## 🏗️ Architecture

```
src/
├── solc.gleam              # Main API module (171 lines)
├── solc/
│   ├── types.gleam         # Core type definitions (175 lines)
│   ├── download.gleam      # Version download functionality (99 lines)
│   ├── wrapper.gleam       # WASM module wrapper (125 lines)
│   └── ffi.gleam          # FFI bindings (28 lines)
├── ffi/
│   └── solc_ffi.mjs       # JavaScript FFI functions (130 lines)
└── test/
    ├── unit_test.gleam           # Basic functionality tests
    ├── integration_test.gleam     # Integration scenarios
    └── end_to_end_test.gleam     # Complete workflow tests
```

**Total: 728 lines of production code with 30 comprehensive tests**

## 🧪 Testing

The library includes comprehensive test coverage:

```bash
# Run all tests
gleam test --target javascript

# Current status: 30 tests passing
```

Test categories:
- **Basic Tests** (4) - Core functionality and type construction
- **Integration Tests** (18) - Real-world scenarios and complex contracts
- **End-to-End Tests** (8) - Complete compilation workflows

## 🛠️ Development

```bash
# Setup
cd gleam_solc
gleam deps download

# Run tests
gleam test --target javascript

# Build for JavaScript
gleam build --target javascript
```

## 🔗 Inspiration

This project was inspired by:
- [solc-js](https://github.com/ethereum/solc-js) - Official JavaScript bindings
- [Solidity Documentation](https://docs.soliditylang.org/) - Compiler reference

---

Built by [pxlvre.eth](https://github.com/pxlvre) with ❤️ using [Gleam](https://gleam.run/) and the [Solidity compiler]((https://github.com/argotorg/solc-bin)).
