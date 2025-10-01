// Solidity compiler download functionality

import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option, None, Some}
import gleam/result
import solc/ffi
import solc/types.{type SolcError, type SolcVersion}

pub type ReleaseInfo {
  ReleaseInfo(
    releases: Dict(String, String),
    latest_release: String,
    builds: List(String),
  )
}

// Download a specific version of the Solidity compiler
pub fn download(
  path: String,
  version: Option(SolcVersion),
) -> Promise(Result(SolcVersion, SolcError)) {
  use release_info <- promise.try_await(fetch_releases())

  let target_version = case version {
    Some(v) -> v
    None -> release_info.latest_release
  }

  case dict.get(release_info.releases, target_version) {
    Ok(filename) -> {
      let url =
        "https://binaries.soliditylang.org/emscripten-wasm32/" <> filename
      use download_result <- promise.map(ffi.download_solc_release(url, path))
      case download_result {
        Ok(_) -> Ok(filename)
        Error(msg) -> Error(types.DownloadError("Download failed: " <> msg))
      }
    }
    Error(_) -> {
      promise.resolve(
        Error(types.VersionNotFound(
          "Version " <> target_version <> " not found",
        )),
      )
    }
  }
}

// Fetch the list of available Solidity releases
pub fn fetch_releases() -> Promise(Result(ReleaseInfo, SolcError)) {
  use response <- promise.map(ffi.fetch_release_list())

  case response {
    Ok(data) -> {
      parse_release_data(data)
      |> result.map_error(fn(msg) {
        types.DownloadError("Failed to parse releases: " <> msg)
      })
    }
    Error(msg) ->
      Error(types.DownloadError("Failed to fetch releases: " <> msg))
  }
}

// Parse the release data from the JSON response  
fn parse_release_data(data: dynamic.Dynamic) -> Result(ReleaseInfo, String) {
  let decoder = release_info_decoder()
  case decode.run(data, decoder) {
    Ok(release_info) -> Ok(release_info)
    Error(_) -> Error("Failed to parse release data")
  }
}

// Decoder for ReleaseInfo
fn release_info_decoder() -> decode.Decoder(ReleaseInfo) {
  use releases <- decode.field(
    "releases",
    decode.dict(decode.string, decode.string),
  )
  use latest_release <- decode.field("latestRelease", decode.string)
  use builds <- decode.field("builds", decode.list(decode.string))
  decode.success(ReleaseInfo(
    releases: releases,
    latest_release: latest_release,
    builds: builds,
  ))
}

// Check if a solc file exists at the given path
pub fn solc_exists(path: String) -> Bool {
  ffi.file_exists(path)
}

// Get the filename for a specific version
pub fn get_filename_for_version(
  version: SolcVersion,
) -> Promise(Result(SolcVersion, SolcError)) {
  use release_info <- promise.map(fetch_releases())

  case release_info {
    Ok(info) -> {
      case dict.get(info.releases, version) {
        Ok(filename) -> Ok(filename)
        Error(_) ->
          Error(types.VersionNotFound("Version " <> version <> " not found"))
      }
    }
    Error(err) -> Error(err)
  }
}
