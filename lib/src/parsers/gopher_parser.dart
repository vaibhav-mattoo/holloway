class GopherLine {
  final String type;
  final String description;
  final String selector;
  final String host;
  final int port;

  GopherLine({
    required this.type,
    required this.description,
    required this.selector,
    required this.host,
    required this.port,
  });

  @override
  String toString() {
    return 'GopherLine{type: $type, description: $description, selector: $selector, host: $host, port: $port}';
  }
}

List<GopherLine> parseGopherResponse(String response) {
  final lines = response.split('\r\n');
  final gopherLines = <GopherLine>[];

  for (final line in lines) {
    if (line.isEmpty) continue;

    final type = line.substring(0, 1);
    final rest = line.substring(1);
    final parts = rest.split('\t');

    if ((type == '0' || type == '1') && parts.length >= 3) {
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
      ));
    } else if (type == 'i' && parts.length >= 1) {
      gopherLines.add(GopherLine(
        type: type,
        description: parts[0],
        selector: '',
        host: '',
        port: 0,
      ));
    } else if (type == 'h' && parts.length >= 3) {
        gopherLines.add(GopherLine(
        type: type,
        description: parts[0],
        selector: parts[1],
        host: parts[2],
        port: 0,
      ));
    } else {
      gopherLines.add(GopherLine(
        type: 'i',
        description: line,
        selector: '',
        host: '',
        port: 0,
      ));
    }
  }

  return gopherLines;
}