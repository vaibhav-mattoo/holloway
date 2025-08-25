import 'package:flutter/material.dart';

/// Represents different types of text elements in Gemini content
enum TextElementType {
  h1,
  h2,
  h3,
  listItem,
  linkItem,
  text,
  monoText,
  quote,
  preformatted,
}

/// Represents a parsed text element with its type and content
class TextElement {
  final TextElementType type;
  final String content;
  final String? url; // For link items
  final String? displayText; // For link items

  TextElement({
    required this.type,
    required this.content,
    this.url,
    this.displayText,
  });

  /// Parse a single line of gemtext
  factory TextElement.fromLine(String line) {
    final trimmed = line.trim();
    
    if (trimmed.startsWith('###') && trimmed.length > 3) {
      final text = trimmed.substring(3).trim();
      return TextElement(type: TextElementType.h3, content: text);
    } else if (trimmed.startsWith('##') && trimmed.length > 2) {
      final text = trimmed.substring(2).trim();
      return TextElement(type: TextElementType.h2, content: text);
    } else if (trimmed.startsWith('#') && trimmed.length > 1) {
      final text = trimmed.substring(1).trim();
      return TextElement(type: TextElementType.h1, content: text);
    } else if (trimmed.startsWith('*') && trimmed.length > 1) {
      final text = trimmed.substring(1).trim();
      return TextElement(type: TextElementType.listItem, content: text);
    } else if (trimmed.startsWith('=>') && trimmed.length > 2) {
      // Parse link format: => URL [display text]
      final linkContent = trimmed.substring(2).trim();
      final parts = linkContent.split(' ');
      
      String? url;
      String? displayText;
      
      if (parts.isNotEmpty) {
        url = parts[0];
        if (parts.length > 1) {
          // Join remaining parts as display text
          displayText = parts.sublist(1).join(' ');
        } else {
          displayText = url; // Use URL as display text if no display text provided
        }
      }
      
      return TextElement(
        type: TextElementType.linkItem,
        content: linkContent,
        url: url,
        displayText: displayText,
      );
    } else if (trimmed.startsWith('```') && trimmed.length > 3) {
      final text = trimmed.substring(3).trim();
      return TextElement(type: TextElementType.monoText, content: text);
    } else if (trimmed.startsWith('>') && trimmed.length > 1) {
      final text = trimmed.substring(1).trim();
      return TextElement(type: TextElementType.quote, content: text);
    } else if (trimmed.isEmpty) {
      return TextElement(type: TextElementType.text, content: '');
    } else {
      return TextElement(type: TextElementType.text, content: trimmed);
    }
  }
}

/// Parse gemtext content into a list of TextElements
List<TextElement> parseGemtext(String content) {
  final lines = content.split('\n');
  final parsed = <TextElement>[];
  
  bool inPreformatted = false;
  List<String> preformattedLines = [];
  
  for (final line in lines) {
    if (line.startsWith('```')) {
      if (inPreformatted) {
        // End of preformatted block
        inPreformatted = false;
        if (preformattedLines.isNotEmpty) {
          parsed.add(TextElement(
            type: TextElementType.preformatted,
            content: preformattedLines.join('\n'),
          ));
          preformattedLines.clear();
        }
      } else {
        // Start of preformatted block
        inPreformatted = true;
        preformattedLines.clear();
      }
    } else if (inPreformatted) {
      preformattedLines.add(line);
    } else {
      parsed.add(TextElement.fromLine(line));
    }
  }
  
  // Handle case where preformatted block doesn't end
  if (inPreformatted && preformattedLines.isNotEmpty) {
    parsed.add(TextElement(
      type: TextElementType.preformatted,
      content: preformattedLines.join('\n'),
    ));
  }
  
  return parsed;
}

/// Convert parsed TextElements to Flutter widgets
class GeminiRenderer extends StatelessWidget {
  final List<TextElement> elements;
  final Function(String)? onLinkTap;
  final TextStyle? baseTextStyle;
  final TextStyle? h1Style;
  final TextStyle? h2Style;
  final TextStyle? h3Style;
  final TextStyle? linkStyle;
  final TextStyle? quoteStyle;
  final TextStyle? monoStyle;

  const GeminiRenderer({
    super.key,
    required this.elements,
    this.onLinkTap,
    this.baseTextStyle,
    this.h1Style,
    this.h2Style,
    this.h3Style,
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
          case TextElementType.h1:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                element.content,
                style: h1Style ?? theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
            
          case TextElementType.h2:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                element.content,
                style: h2Style ?? theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            );
            
          case TextElementType.h3:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                element.content,
                style: h3Style ?? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                    child: Text(element.content, style: defaultTextStyle),
                  ),
                ],
              ),
            );
            
          case TextElementType.linkItem:
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
                element.content,
                style: quoteStyle ?? defaultTextStyle?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
            
          case TextElementType.monoText:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                element.content,
                                 style: monoStyle ?? defaultTextStyle?.copyWith(
                   fontFamily: 'monospace',
                   backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                 ),
              ),
            );
            
          case TextElementType.preformatted:
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(12.0),
                             decoration: BoxDecoration(
                 color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                 borderRadius: BorderRadius.circular(8.0),
                 border: Border.all(
                   color: theme.colorScheme.outline.withValues(alpha: 0.3),
                 ),
               ),
              child: Text(
                element.content,
                style: monoStyle ?? defaultTextStyle?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            );
            
          case TextElementType.text:
            if (element.content.isEmpty) {
              return const SizedBox(height: 8.0);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(element.content, style: defaultTextStyle),
            );
        }
      },
    );
  }
}
