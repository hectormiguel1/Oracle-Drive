import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:fabula_nova_sdk/bridge_generated/api.dart' as sdk;
import 'package:fabula_nova_sdk/bridge_generated/modules/crystalium/structs.dart'
    as cgt_sdk;
import 'package:oracle_drive/src/services/core/error_handler.dart';

/// Service for CGT/MCP (Crystalium) file operations.
///
/// CGT (Crystal Graph Tree) and MCP (Master Crystal Pattern) files
/// are used in the FF13 trilogy for the Crystarium character
/// progression system.
class CgtService with NativeErrorHandler {
  static CgtService? _instance;
  static CgtService get instance => _instance ??= CgtService._();

  final Logger _logger = Logger('CgtService');

  @override
  Logger get logger => _logger;

  CgtService._();

  // ========================================
  // CGT Operations
  // ========================================

  /// Parses a CGT file from disk.
  ///
  /// # Arguments
  /// * [filePath] - Path to the CGT file.
  ///
  /// # Returns
  /// Parsed CGT data with entries and nodes.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<cgt_sdk.CgtFile> parseCgt(String filePath) async {
    return safeCall('CGT Parse', () async {
      return await sdk.cgtParse(inFile: filePath);
    });
  }

  /// Parses a CGT file from memory.
  ///
  /// # Arguments
  /// * [bytes] - Raw CGT file bytes.
  ///
  /// # Returns
  /// Parsed CGT data.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<cgt_sdk.CgtFile> parseCgtFromMemory(Uint8List bytes) async {
    return safeCall('CGT Parse From Memory', () async {
      return await sdk.cgtParseFromMemory(data: bytes);
    });
  }

  /// Writes a CGT file to disk.
  ///
  /// # Arguments
  /// * [cgt] - CGT data to write.
  /// * [filePath] - Output file path.
  ///
  /// # Throws
  /// [NativeError] if writing fails.
  Future<void> writeCgt(cgt_sdk.CgtFile cgt, String filePath) async {
    return safeCall('CGT Write', () async {
      await sdk.cgtWrite(cgt: cgt, outFile: filePath);
    });
  }

  /// Writes a CGT file to memory.
  ///
  /// # Arguments
  /// * [cgt] - CGT data to serialize.
  ///
  /// # Returns
  /// Serialized CGT bytes.
  ///
  /// # Throws
  /// [NativeError] if serialization fails.
  Future<Uint8List> writeCgtToMemory(cgt_sdk.CgtFile cgt) async {
    return safeCall('CGT Write To Memory', () async {
      return await sdk.cgtWriteToMemory(cgt: cgt);
    });
  }

  /// Converts a CGT file to JSON format.
  ///
  /// # Arguments
  /// * [cgt] - CGT data to convert.
  ///
  /// # Returns
  /// JSON string representation.
  Future<String> cgtToJson(cgt_sdk.CgtFile cgt) async {
    return safeCall('CGT To JSON', () async {
      return await sdk.cgtToJson(cgt: cgt);
    });
  }

  /// Parses a CGT file from JSON string.
  ///
  /// # Arguments
  /// * [json] - JSON string to parse.
  ///
  /// # Returns
  /// Parsed CGT data.
  Future<cgt_sdk.CgtFile> cgtFromJson(String json) async {
    return safeCall('CGT From JSON', () async {
      return await sdk.cgtFromJson(json: json);
    });
  }

  /// Validates a CGT file structure.
  ///
  /// # Arguments
  /// * [cgt] - CGT data to validate.
  ///
  /// # Returns
  /// List of validation warnings (empty if valid).
  Future<List<String>> validateCgt(cgt_sdk.CgtFile cgt) async {
    return safeCall('CGT Validate', () async {
      return await sdk.cgtValidate(cgt: cgt);
    });
  }

  // ========================================
  // MCP Operations
  // ========================================

  /// Parses an MCP file from disk.
  ///
  /// # Arguments
  /// * [filePath] - Path to the MCP file.
  ///
  /// # Returns
  /// Parsed MCP data with patterns.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<cgt_sdk.McpFile> parseMcp(String filePath) async {
    return safeCall('MCP Parse', () async {
      return await sdk.mcpParse(inFile: filePath);
    });
  }

  /// Parses an MCP file from memory.
  ///
  /// # Arguments
  /// * [bytes] - Raw MCP file bytes.
  ///
  /// # Returns
  /// Parsed MCP data.
  ///
  /// # Throws
  /// [NativeError] if parsing fails.
  Future<cgt_sdk.McpFile> parseMcpFromMemory(Uint8List bytes) async {
    return safeCall('MCP Parse From Memory', () async {
      return await sdk.mcpParseFromMemory(data: bytes);
    });
  }

  /// Converts an MCP file to JSON format.
  ///
  /// # Arguments
  /// * [mcp] - MCP data to convert.
  ///
  /// # Returns
  /// JSON string representation.
  Future<String> mcpToJson(cgt_sdk.McpFile mcp) async {
    return safeCall('MCP To JSON', () async {
      return await sdk.mcpToJson(mcp: mcp);
    });
  }

  /// Parses an MCP file from JSON string.
  ///
  /// # Arguments
  /// * [json] - JSON string to parse.
  ///
  /// # Returns
  /// Parsed MCP data.
  Future<cgt_sdk.McpFile> mcpFromJson(String json) async {
    return safeCall('MCP From JSON', () async {
      return await sdk.mcpFromJson(json: json);
    });
  }
}
