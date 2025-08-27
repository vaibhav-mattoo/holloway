/// Represents different types of text elements in Finger content
enum FingerTextElementType {
  text,           // Regular text line
  link,           // URL links (HTTP/HTTPS)
  email,          // Email addresses
  timestamp,      // Timestamp information
  status,         // Status information
}

/// Represents a parsed Finger text element
class FingerTextElement {
  final FingerTextElementType type;
  final String content;
  final String? url; // For link elements
  final String? displayText; // For link elements

  FingerTextElement({
    required this.type,
    required this.content,
    this.url,
    this.displayText,
  });

  /// Parse a single line of Finger content
  factory FingerTextElement.fromLine(String line) {
    final trimmed = line.trim();
    
    // Check for email addresses
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    if (emailPattern.hasMatch(trimmed)) {
      final email = emailPattern.firstMatch(trimmed)!.group(0)!;
      return FingerTextElement(
        type: FingerTextElementType.email,
        content: line,
        url: 'mailto:$email',
        displayText: email,
      );
    }
    
    // Check for HTTP/HTTPS URLs
    final urlPattern = RegExp(r'https?://[^\s]+');
    if (urlPattern.hasMatch(trimmed)) {
      final url = urlPattern.firstMatch(trimmed)!.group(0)!;
      return FingerTextElement(
        type: FingerTextElementType.link,
        content: line,
        url: url,
        displayText: url,
      );
    }
    
    // Check for timestamp patterns
    if (trimmed.contains('T') && trimmed.contains('Z') || 
        trimmed.contains('GMT') || 
        trimmed.contains('UTC')) {
      return FingerTextElement(
        type: FingerTextElementType.timestamp,
        content: line,
      );
    }
    
    // Check for status indicators
    if (trimmed.startsWith('Status:') || 
        trimmed.startsWith('Online') || 
        trimmed.startsWith('Offline') ||
        trimmed.startsWith('Away')) {
      return FingerTextElement(
        type: FingerTextElementType.status,
        content: line,
      );
    }
    
    // Default: regular text
    return FingerTextElement(
      type: FingerTextElementType.text,
      content: line,
    );
  }
}

/// Parse Finger content into structured elements
List<FingerTextElement> parseFingerContent(String content) {
  final lines = content.split('\n');
  final parsed = <FingerTextElement>[];
  
  for (final line in lines) {
    if (line.trim().isNotEmpty) {
      parsed.add(FingerTextElement.fromLine(line));
    }
  }
  
  return parsed;
}

/// Extract all URLs from Finger content
List<String> extractUrls(String content) {
  final urlPattern = RegExp(r'https?://[^\s]+');
  final matches = urlPattern.allMatches(content);
  return matches.map((match) => match.group(0)!).toList();
}

/// Extract all email addresses from Finger content
List<String> extractEmails(String content) {
  final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
  final matches = emailPattern.allMatches(content);
  return matches.map((match) => match.group(0)!).toList();
}

/// Clean up Finger content by removing control characters
String cleanupFingerContent(String content) {
  // Remove common control characters that might appear in Finger responses
  return content
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}
