import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../parsers/gemini_parser.dart';
import '../parsers/gopher_parser.dart';

/// Main content renderer that handles all protocol types
class ContentRenderer extends StatelessWidget {
  final String content;
  final String? baseUrl;
  final String protocol;
  final Function(String)? onNavigate;

  const ContentRenderer({
    super.key,
    required this.content,
    this.baseUrl,
    required this.protocol,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    switch (protocol.toLowerCase()) {
      case 'gemini':
        return _buildGeminiContent(context);
      case 'gopher':
        return _buildGopherContent(context);
      case 'finger':
        return _buildFingerContent(context);
      default:
        return _buildPlainText(context);
    }
  }

  Widget _buildGeminiContent(BuildContext context) {
    // Check if this is an error response
    if (content.startsWith('Failed to fetch')) {
      return _buildErrorContent(context, content);
    }

    // Check if this is a Gemini response with status
    if (content.startsWith('Status:')) {
      final lines = content.split('\n');
      String geminiContent = '';
      bool foundBody = false;

      for (final line in lines) {
        if (foundBody) {
          geminiContent = '$geminiContent$line\n';
        } else if (line.trim().isEmpty) {
          foundBody = true;
        }
      }

      if (geminiContent.isNotEmpty) {
        final elements = parseGemtext(geminiContent, baseUrl: baseUrl);
        return GeminiRenderer(
          elements: elements,
          onLinkTap: (url) => _handleLinkTap(url, context),
        );
      }
    }

    // If no status header, treat as raw Gemini content
    final elements = parseGemtext(content, baseUrl: baseUrl);
    return GeminiRenderer(
      elements: elements,
      onLinkTap: (url) => _handleLinkTap(url, context),
    );
  }

  Widget _buildGopherContent(BuildContext context) {
    final lines = parseGopherResponse(content);
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return _buildGopherLine(context, line);
      },
    );
  }

  Widget _buildGopherLine(BuildContext context, GopherLine line) {
    final theme = Theme.of(context);
    final itemType = line.itemType;
    
    // Info lines are just displayed as text
    if (itemType == GopherItemType.info) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          line.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    
    // All other types are displayed as list tiles
    return ListTile(
      leading: Icon(
        getGopherTypeIcon(itemType),
        color: getGopherTypeColor(itemType),
        size: 20,
      ),
      title: Text(
        line.description,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: line.host.isNotEmpty ? Text(
        '${line.host}:${line.port}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ) : null,
      trailing: line.host.isNotEmpty ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: getGopherTypeColor(itemType).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          getGopherTypeName(itemType),
          style: theme.textTheme.bodySmall?.copyWith(
            color: getGopherTypeColor(itemType),
            fontWeight: FontWeight.w500,
          ),
        ),
      ) : null,
      onTap: () => _handleGopherItemTap(line),
    );
  }

  Widget _buildFingerContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with protocol info
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Finger Protocol',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Content with link detection
            _buildFingerTextWithLinks(context, content),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerTextWithLinks(BuildContext context, String text) {
    final theme = Theme.of(context);
    final lines = text.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Detect URLs in the line
        final urlPattern = RegExp(r'https?://[^\s]+');
        final matches = urlPattern.allMatches(line);
        
        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: SelectableText(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          );
        }
        
        // Line contains URLs, split and render with clickable links
        final parts = <Widget>[];
        int lastIndex = 0;
        
        for (final match in matches) {
          // Add text before the URL
          if (match.start > lastIndex) {
            parts.add(SelectableText(
              line.substring(lastIndex, match.start),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ));
          }
          
          // Add the clickable URL
          final url = line.substring(match.start, match.end);
          parts.add(
            InkWell(
              onTap: () => _handleExternalLink(url),
              child: Text(
                url,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          );
          
          lastIndex = match.end;
        }
        
        // Add remaining text after the last URL
        if (lastIndex < line.length) {
          parts.add(SelectableText(
            line.substring(lastIndex),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ));
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Wrap(children: parts),
        );
      }).toList(),
    );
  }

  Widget _buildPlainText(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLinkTap(String url, BuildContext context) {
    // Validate the URL before processing
    if (url.isEmpty) return;
    
    // Fix malformed URLs that start with ://
    if (url.startsWith('://')) {
      url = 'gemini$url';
    }
    
    // Ensure URLs without scheme get gemini:// prefix
    if (!url.contains('://')) {
      url = 'gemini://$url';
    }
    
    if (onNavigate != null) {
      onNavigate!(url);
    } else {
      // Fallback to external handling
      _handleExternalLink(url);
    }
  }

  void _handleGopherItemTap(GopherLine line) {
    if (line.isNavigable) {
      // Navigate to the Gopher item
      var selector = line.selector;
      if (!selector.startsWith('/')) {
        selector = '/$selector';
      }
      final url = 'gopher://${line.host}:${line.port}$selector';
      
      if (onNavigate != null) {
        onNavigate!(url);
      }
    } else if (line.isDownloadable) {
      // Handle file download
      _handleGopherFileDownload(line);
    } else if (line.isExternal) {
      // Handle external links
      _handleGopherExternalLink(line);
    }
  }

  void _handleGopherFileDownload(GopherLine line) {
    // For now, just show a snackbar indicating download functionality
    // In a real implementation, this would trigger a download
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('Download: ${line.description}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleGopherExternalLink(GopherLine line) {
    String externalUrl = '';
    
    switch (line.itemType) {
      case GopherItemType.http:
        externalUrl = 'http://${line.host}:${line.port}${line.selector}';
        break;
      case GopherItemType.https:
        externalUrl = 'https://${line.host}:${line.port}${line.selector}';
        break;
      case GopherItemType.telnet:
      case GopherItemType.tn3270:
      case GopherItemType.telnet3270:
        externalUrl = 'telnet://${line.host}:${line.port}';
        break;
      default:
        return;
    }
    
    _handleExternalLink(externalUrl);
  }

  void _handleExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle URL parsing errors
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Could not open: $url'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

// Global navigator key for showing snackbars
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
