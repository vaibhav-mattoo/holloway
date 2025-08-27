import 'package:flutter/material.dart';

/// Represents different types of Gopher content
enum GopherItemType {
  textFile,       // 0 - Text file
  directory,      // 1 - Directory
  cso,           // 2 - CSO phone-book server
  error,         // 3 - Error
  binHex,        // 4 - BinHexed Macintosh file
  dosBinary,     // 5 - DOS binary file
  uuencoded,     // 6 - UUencoded file
  search,        // 7 - Gopher search
  telnet,        // 8 - Telnet session
  binary,        // 9 - Binary file
  redundant,     // + - Redundant server
  tn3270,        // T - TN3270 session
  gif,           // g - GIF image
  image,         // I - Image
  telnet3270,    // i - Telnet 3270 session
  info,          // i - Information line
  http,          // h - HTTP link
  https,         // H - HTTPS link
  unknown,       // ? - Unknown type
}

/// Represents a parsed Gopher line
class GopherLine {
  final String type;
  final String description;
  final String selector;
  final String host;
  final int port;
  final GopherItemType itemType;

  GopherLine({
    required this.type,
    required this.description,
    required this.selector,
    required this.host,
    required this.port,
    required this.itemType,
  });

  @override
  String toString() {
    return 'GopherLine{type: $type, description: $description, selector: $selector, host: $host, port: $port, itemType: $itemType}';
  }

  /// Check if this item is navigable (can be clicked to navigate)
  bool get isNavigable {
    return itemType == GopherItemType.textFile ||
           itemType == GopherItemType.directory ||
           itemType == GopherItemType.search;
  }

  /// Check if this item is a file that can be downloaded
  bool get isDownloadable {
    return itemType == GopherItemType.binary ||
           itemType == GopherItemType.dosBinary ||
           itemType == GopherItemType.binHex ||
           itemType == GopherItemType.uuencoded ||
           itemType == GopherItemType.gif ||
           itemType == GopherItemType.image;
  }

  /// Check if this item opens an external application
  bool get isExternal {
    return itemType == GopherItemType.http ||
           itemType == GopherItemType.https ||
           itemType == GopherItemType.telnet ||
           itemType == GopherItemType.tn3270 ||
           itemType == GopherItemType.telnet3270;
  }
}

/// Parse Gopher response into structured lines
List<GopherLine> parseGopherResponse(String response) {
  final lines = response.split('\r\n');
  final gopherLines = <GopherLine>[];

  for (final line in lines) {
    if (line.isEmpty) continue;

    final type = line.substring(0, 1);
    final rest = line.substring(1);
    final parts = rest.split('\t');

    if (parts.isNotEmpty && parts.length >= 3) {
      final port = int.tryParse(parts.last) ?? 70;
      final host = parts[parts.length - 2];
      final selector = parts[parts.length - 3];
      final description = parts.sublist(0, parts.length - 3).join('\t');
      
      gopherLines.add(GopherLine(
        type: type,
        description: description,
        selector: selector,
        host: host,
        port: port,
        itemType: _parseGopherType(type),
      ));
    } else if (type == 'i' && parts.isNotEmpty) {
      // Info line
      gopherLines.add(GopherLine(
        type: type,
        description: parts[0],
        selector: '',
        host: '',
        port: 0,
        itemType: GopherItemType.info,
      ));
    } else {
      // Unknown or malformed line, treat as info
      gopherLines.add(GopherLine(
        type: type,
        description: line,
        selector: '',
        host: '',
        port: 0,
        itemType: GopherItemType.unknown,
      ));
    }
  }

  return gopherLines;
}

/// Parse Gopher type character into enum
GopherItemType _parseGopherType(String type) {
  switch (type) {
    case '0':
      return GopherItemType.textFile;
    case '1':
      return GopherItemType.directory;
    case '2':
      return GopherItemType.cso;
    case '3':
      return GopherItemType.error;
    case '4':
      return GopherItemType.binHex;
    case '5':
      return GopherItemType.dosBinary;
    case '6':
      return GopherItemType.uuencoded;
    case '7':
      return GopherItemType.search;
    case '8':
      return GopherItemType.telnet;
    case '9':
      return GopherItemType.binary;
    case '+':
      return GopherItemType.redundant;
    case 'T':
      return GopherItemType.tn3270;
    case 'g':
      return GopherItemType.gif;
    case 'I':
      return GopherItemType.image;
    case 'i':
      return GopherItemType.info;
    case 'h':
      return GopherItemType.http;
    case 'H':
      return GopherItemType.https;
    case '?':
      return GopherItemType.unknown;
    default:
      return GopherItemType.unknown;
  }
}

/// Get a user-friendly name for a Gopher item type
String getGopherTypeName(GopherItemType type) {
  switch (type) {
    case GopherItemType.textFile:
      return 'Text File';
    case GopherItemType.directory:
      return 'Directory';
    case GopherItemType.cso:
      return 'CSO Phone Book';
    case GopherItemType.error:
      return 'Error';
    case GopherItemType.binHex:
      return 'BinHex File';
    case GopherItemType.dosBinary:
      return 'DOS Binary';
    case GopherItemType.uuencoded:
      return 'UUencoded File';
    case GopherItemType.search:
      return 'Search';
    case GopherItemType.telnet:
      return 'Telnet Session';
    case GopherItemType.binary:
      return 'Binary File';
    case GopherItemType.redundant:
      return 'Redundant Server';
    case GopherItemType.tn3270:
      return 'TN3270 Session';
    case GopherItemType.gif:
      return 'GIF Image';
    case GopherItemType.image:
      return 'Image';
    case GopherItemType.telnet3270:
      return 'Telnet 3270';
    case GopherItemType.info:
      return 'Information';
    case GopherItemType.http:
      return 'HTTP Link';
    case GopherItemType.https:
      return 'HTTPS Link';
    case GopherItemType.unknown:
      return 'Unknown';
  }
}

/// Get an appropriate icon for a Gopher item type
IconData getGopherTypeIcon(GopherItemType type) {
  switch (type) {
    case GopherItemType.textFile:
      return Icons.description;
    case GopherItemType.directory:
      return Icons.folder;
    case GopherItemType.cso:
      return Icons.contacts;
    case GopherItemType.error:
      return Icons.error;
    case GopherItemType.binHex:
    case GopherItemType.dosBinary:
    case GopherItemType.uuencoded:
    case GopherItemType.binary:
      return Icons.file_download;
    case GopherItemType.search:
      return Icons.search;
    case GopherItemType.telnet:
    case GopherItemType.tn3270:
    case GopherItemType.telnet3270:
      return Icons.terminal;
    case GopherItemType.redundant:
      return Icons.sync;
    case GopherItemType.gif:
    case GopherItemType.image:
      return Icons.image;
    case GopherItemType.info:
      return Icons.info;
    case GopherItemType.http:
    case GopherItemType.https:
      return Icons.language;
    case GopherItemType.unknown:
      return Icons.help_outline;
  }
}

/// Get a color for a Gopher item type
Color getGopherTypeColor(GopherItemType type) {
  switch (type) {
    case GopherItemType.textFile:
      return Colors.blue;
    case GopherItemType.directory:
      return Colors.orange;
    case GopherItemType.cso:
      return Colors.purple;
    case GopherItemType.error:
      return Colors.red;
    case GopherItemType.binHex:
    case GopherItemType.dosBinary:
    case GopherItemType.uuencoded:
    case GopherItemType.binary:
      return Colors.orange;
    case GopherItemType.search:
      return Colors.green;
    case GopherItemType.telnet:
    case GopherItemType.tn3270:
    case GopherItemType.telnet3270:
      return Colors.teal;
    case GopherItemType.redundant:
      return Colors.indigo;
    case GopherItemType.gif:
    case GopherItemType.image:
      return Colors.green;
    case GopherItemType.info:
      return Colors.grey;
    case GopherItemType.http:
    case GopherItemType.https:
      return Colors.purple;
    case GopherItemType.unknown:
      return Colors.grey;
  }
}