import 'package:flutter/material.dart';

/// Represents different types of text elements in Gemini content
/// Based on the official Gemini specification
enum TextElementType {
  text,           // Default line type
  link,           // Lines beginning with "=>"
  preformatToggle, // Lines beginning with "```"
  heading,        // Lines beginning with "#", "##", or "###"
  listItem,       // Lines beginning with "* "
  quote,          // Lines beginning with ">"
}

/// Represents a parsed text element with its type and content
class TextElement {
  final TextElementType type;
  final String content;
  final String? url; // For link elements
  final String? displayText; // For link elements
  final int? headingLevel; // For heading elements (1, 2, or 3)
  final String? altText; // For preformat toggle elements

  TextElement({
    required this.type,
    required this.content,
    this.url,
    this.displayText,
    this.headingLevel,
    this.altText,
  });

  /// Parse a single line according to the Gemini specification
  /// This method handles the line in isolation as required by the spec
  factory TextElement.fromLine(String line, bool inPreformattedMode, {String? baseUrl}) {
    final trimmed = line.trim();
    
    if (inPreformattedMode) {
      // In pre-formatted mode, only preformat toggle lines are special
      if (trimmed.startsWith('```')) {
        // Extract alt text (everything after ```)
        final altText = trimmed.length > 3 ? trimmed.substring(3).trim() : null;
        return TextElement(
          type: TextElementType.preformatToggle,
          content: line, // Keep original line for state management
          altText: altText,
        );
      } else {
        // All other lines are text lines in pre-formatted mode
        return TextElement(
          type: TextElementType.text,
          content: line, // Keep original line (no trimming in pre-formatted mode)
        );
      }
    } else {
      // In normal mode, check for all line types
      if (trimmed.startsWith('```')) {
        // Preformat toggle line
        final altText = trimmed.length > 3 ? trimmed.substring(3).trim() : null;
        return TextElement(
          type: TextElementType.preformatToggle,
          content: line,
          altText: altText,
        );
      } else if (trimmed.startsWith('=>')) {
        // Link line: =>[<whitespace>]<URL>[<whitespace><USER-FRIENDLY LINK NAME>]
        final linkContent = trimmed.substring(2).trim();
        final parts = linkContent.split(RegExp(r'\s+'));
        
        String? url;
        String? displayText;
        
        if (parts.isNotEmpty) {
          url = parts[0];
          
          // Resolve relative URLs against base URL if provided
          if (baseUrl != null && !url.startsWith('gemini://') && !url.startsWith('http://') && !url.startsWith('https://')) {
            url = _resolveRelativeUrl(baseUrl, url);
          }
          
          if (parts.length > 1) {
            // Join remaining parts as display text
            displayText = parts.sublist(1).join(' ');
          } else {
            displayText = url; // Use URL as display text if no display text provided
          }
        }
        
        return TextElement(
          type: TextElementType.link,
          content: line,
          url: url,
          displayText: displayText,
        );
      } else if (trimmed.startsWith('#')) {
        // Heading line: #, ##, or ###
        int level = 0;
        int i = 0;
        while (i < trimmed.length && i < 3 && trimmed[i] == '#') {
          level++;
          i++;
        }
        
        if (level >= 1 && level <= 3) {
          return TextElement(
            type: TextElementType.heading,
            content: line,
            headingLevel: level,
          );
        }
      } else if (trimmed.startsWith('* ')) {
        // List item: * followed by space
        return TextElement(
          type: TextElementType.listItem,
          content: line,
        );
      } else if (trimmed.startsWith('>')) {
        // Quote line: > followed by text
        return TextElement(
          type: TextElementType.quote,
          content: line,
        );
      }
      
      // Default: text line (including empty lines)
      return TextElement(
        type: TextElementType.text,
        content: line,
      );
    }
  }
}

/// Parse gemtext content according to the official specification
/// Maintains parser state and handles each line in isolation
/// Optionally resolves relative URLs against a base URL
List<TextElement> parseGemtext(String content, {String? baseUrl}) {
  final lines = content.split('\n');
  final parsed = <TextElement>[];
  
  // Parser state: false = normal mode, true = pre-formatted mode
  // MUST start in normal mode per specification
  bool inPreformattedMode = false;
  
  for (final line in lines) {
    // Parse each line in isolation based on current parser state
    final element = TextElement.fromLine(line, inPreformattedMode, baseUrl: baseUrl);
    
    // Handle preformat toggle lines (they change parser state)
    if (element.type == TextElementType.preformatToggle) {
      // Toggle between normal and pre-formatted mode
      inPreformattedMode = !inPreformattedMode;
      // Don't add toggle lines to output (per specification)
      continue;
    }
    
    // Add all other elements to the parsed list
    parsed.add(element);
  }
  
  return parsed;
}

/// Resolve a relative URL against a base URL
/// Handles both absolute and relative paths correctly
String _resolveRelativeUrl(String baseUrl, String relativeUrl) {
  try {
    // Parse the base URL
    final baseUri = Uri.parse(baseUrl);
    
    // Handle different types of relative URLs
    final portString = baseUri.hasPort ? ':${baseUri.port}' : '';
    
    if (relativeUrl.startsWith('/')) {
      // Absolute path from root of domain
      return '${baseUri.scheme}://${baseUri.host}$portString$relativeUrl';
    } else if (relativeUrl.startsWith('./')) {
      // Relative path from current directory
      final currentPath = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
      final resolvedPath = currentPath + relativeUrl.substring(2);
      return '${baseUri.scheme}://${baseUri.host}$portString$resolvedPath';
    } else if (relativeUrl.startsWith('../')) {
      // Go up directories
      final pathSegments = baseUri.pathSegments.toList();
      int upCount = 0;
      String remainingPath = relativeUrl;
      
      while (remainingPath.startsWith('../')) {
        upCount++;
        remainingPath = remainingPath.substring(3);
      }
      
      // Remove the appropriate number of path segments
      for (int i = 0; i < upCount && pathSegments.isNotEmpty; i++) {
        pathSegments.removeLast();
      }
      
      final resolvedPath = '/${pathSegments.join('/')}${remainingPath.isNotEmpty ? '/$remainingPath' : ''}';
      return '${baseUri.scheme}://${baseUri.host}$portString$resolvedPath';
    } else {
      // Simple relative path (same directory)
      final currentPath = baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/';
      final resolvedPath = currentPath + relativeUrl;
      return '${baseUri.scheme}://${baseUri.host}$portString$resolvedPath';
    }
  } catch (e) {
    // If URL parsing fails, return the original relative URL
    return relativeUrl;
  }
}

/// Convert parsed TextElements to Flutter widgets
/// Implements rendering according to the Gemini specification
class GeminiRenderer extends StatelessWidget {
  final List<TextElement> elements;
  final Function(String)? onLinkTap;
  final TextStyle? baseTextStyle;
  final TextStyle? headingStyle;
  final TextStyle? linkStyle;
  final TextStyle? quoteStyle;
  final TextStyle? monoStyle;

  const GeminiRenderer({
    super.key,
    required this.elements,
    this.onLinkTap,
    this.baseTextStyle,
    this.headingStyle,
    this.linkStyle,
    this.quoteStyle,
    this.monoStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = baseTextStyle ?? theme.textTheme.bodyMedium;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: elements.length,
      itemBuilder: (context, index) {
        final element = elements[index];
        
        switch (element.type) {
          case TextElementType.heading:
            final level = element.headingLevel ?? 1;
            TextStyle? style;
            
            switch (level) {
              case 1:
                style = headingStyle ?? theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                );
                break;
              case 2:
                style = headingStyle ?? theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                );
                break;
              case 3:
                style = headingStyle ?? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                );
                break;
            }
            
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: level == 1 ? 16.0 : level == 2 ? 12.0 : 8.0,
              ),
              child: Text(
                element.content.substring(element.headingLevel ?? 1).trim(),
                style: style,
              ),
            );
            
          case TextElementType.listItem:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: defaultTextStyle),
                  Expanded(
                    child: Text(
                      element.content.substring(2).trim(),
                      style: defaultTextStyle,
                    ),
                  ),
                ],
              ),
            );
            
          case TextElementType.link:
            if (element.url != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  onTap: () => onLinkTap?.call(element.url!),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (element.displayText != null && element.displayText != element.url)
                          Text(
                            element.displayText!,
                            style: linkStyle ?? defaultTextStyle?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        Text(
                          element.url!,
                          style: linkStyle ?? defaultTextStyle?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
            
          case TextElementType.quote:
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 4.0,
                  ),
                ),
              ),
              child: Text(
                element.content.substring(1).trim(),
                style: quoteStyle ?? defaultTextStyle?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
            
          case TextElementType.text:
            // Handle empty lines as specified: render as vertical blank space
            if (element.content.trim().isEmpty) {
              return const SizedBox(height: 8.0);
            }
            
            // Regular text lines - wrap to fit viewport as per specification
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                element.content,
                style: defaultTextStyle,
                // Text wrapping is handled by the Text widget automatically
              ),
            );
            
          case TextElementType.preformatToggle:
            // Preformat toggle lines should not be rendered (per specification)
            // They are only used for parser state management
            return const SizedBox.shrink();
        }
      },
    );
  }
}
