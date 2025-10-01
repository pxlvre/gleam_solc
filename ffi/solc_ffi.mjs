// JavaScript FFI for Solidity compiler integration
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync } from 'node:fs';
import https from 'node:https';
import http from 'node:http';

// Create require function for loading CommonJS modules
const require = createRequire(import.meta.url);

// Load a solc module from file path
export function load_solc_module(path) {
  try {
    // Clear require cache to allow reloading
    delete require.cache[require.resolve(path)];
    const soljson = require(path);
    return { tag: "Ok", value: soljson };
  } catch (error) {
    return { tag: "Error", value: error.message };
  }
}

// Get version from loaded solc module
export function get_solc_version(soljson) {
  try {
    // Set up minimal bindings to get version
    const cwrap = soljson.cwrap;
    const version = cwrap('solidity_version', 'string', []);
    return { tag: "Ok", value: version() };
  } catch (error) {
    return { tag: "Error", value: error.message };
  }
}

// Get license from loaded solc module  
export function get_solc_license(soljson) {
  try {
    const cwrap = soljson.cwrap;
    const license = cwrap('solidity_license', 'string', []);
    return { tag: "Ok", value: license() };
  } catch (error) {
    return { tag: "Error", value: error.message };
  }
}

// Compile Solidity using standard JSON interface
export function compile_solidity(soljson, input_json) {
  try {
    const cwrap = soljson.cwrap;
    const compile = cwrap('solidity_compile', 'string', ['string', 'number', 'number']);
    
    // Simple compilation without callbacks for now
    const result = compile(input_json, 0, 0);
    return { tag: "Ok", value: result };
  } catch (error) {
    return { tag: "Error", value: error.message };
  }
}

// Download solc release from GitHub
export function download_solc_release(url, path) {
  return new Promise((resolve) => {
    const protocol = url.startsWith('https:') ? https : http;
    
    const request = protocol.get(url, (response) => {
      if (response.statusCode === 200) {
        let data = '';
        response.setEncoding('utf8');
        
        response.on('data', (chunk) => {
          data += chunk;
        });
        
        response.on('end', () => {
          try {
            writeFileSync(path, data);
            resolve({ tag: "Ok", value: path });
          } catch (error) {
            resolve({ tag: "Error", value: error.message });
          }
        });
      } else {
        resolve({ tag: "Error", value: `HTTP ${response.statusCode}` });
      }
    });
    
    request.on('error', (error) => {
      resolve({ tag: "Error", value: error.message });
    });
  });
}

// Fetch release list from Solidity releases
export function fetch_release_list() {
  return new Promise((resolve) => {
    const url = 'https://binaries.soliditylang.org/emscripten-wasm32/list.json';
    
    https.get(url, (response) => {
      if (response.statusCode === 200) {
        let data = '';
        response.setEncoding('utf8');
        
        response.on('data', (chunk) => {
          data += chunk;
        });
        
        response.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ tag: "Ok", value: parsed });
          } catch (error) {
            resolve({ tag: "Error", value: error.message });
          }
        });
      } else {
        resolve({ tag: "Error", value: `HTTP ${response.statusCode}` });
      }
    }).on('error', (error) => {
      resolve({ tag: "Error", value: error.message });
    });
  });
}

// Helper to check if file exists
export function file_exists(path) {
  try {
    readFileSync(path);
    return true;
  } catch {
    return false;
  }
}