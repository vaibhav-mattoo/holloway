use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::Duration;
use url::Url;
use native_tls::TlsConnector;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

/// Navigate to a Gemini URL and return the plaintext content
#[flutter_rust_bridge::frb]
pub async fn navigate(url: String) -> Result<String, String> {
    // Parse the URL to validate it's a Gemini URL
    let parsed_url = match Url::parse(&url) {
        Ok(url) => url,
        Err(_) => return Err("Invalid URL format".to_string()),
    };
    
    // Check if it's a Gemini URL
    if parsed_url.scheme() != "gemini" {
        return Err("Only gemini:// URLs are supported".to_string());
    }
    
    // Extract host and port
    let host = match parsed_url.host_str() {
        Some(h) => h,
        None => return Err("Invalid host in URL".to_string()),
    };
    let port = parsed_url.port().unwrap_or(1965);
    
    // Connect to Gemini server
    match connect_and_fetch(host, port, &url).await {
        Ok(content) => Ok(content),
        Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
    }
}

/// Get the default start page URL
#[flutter_rust_bridge::frb(sync)]
pub fn get_start_page() -> String {
    "gemini://gemini.circumlunar.space/".to_string()
}

/// Connect to Gemini server and fetch content
async fn connect_and_fetch(host: &str, port: u16, url: &str) -> Result<String, String> {
    // Create socket address
    let socket_addr = format!("{}:{}", host, port);
    
    // Connect TCP stream using ToSocketAddrs trait
    let tcp_stream = match socket_addr.to_socket_addrs() {
        Ok(mut addrs_iter) => {
            match addrs_iter.next() {
                Some(addr) => {
                    match TcpStream::connect_timeout(&addr, Duration::new(10, 0)) {
                        Ok(stream) => stream,
                        Err(e) => return Err(format!("TCP connection failed: {}", e)),
                    }
                },
                None => return Err("No socket addresses found".to_string()),
            }
        },
        Err(e) => return Err(format!("Failed to resolve socket address: {}", e)),
    };
    
    // Create TLS connector (accepting invalid certs for simplicity)
    let mut builder = TlsConnector::builder();
    builder.danger_accept_invalid_hostnames(true);
    builder.danger_accept_invalid_certs(true);
    
    let connector = match builder.build() {
        Ok(c) => c,
        Err(e) => return Err(format!("TLS connector creation failed: {}", e)),
    };
    
    // Establish TLS connection
    let mut tls_stream = match connector.connect(host, tcp_stream) {
        Ok(stream) => stream,
        Err(e) => return Err(format!("TLS connection failed: {}", e)),
    };
    
    // Send Gemini request
    let request = format!("{}\r\n", url);
    if let Err(e) = tls_stream.write_all(request.as_bytes()) {
        return Err(format!("Failed to send request: {}", e));
    }
    
    // Read response
    let mut response = Vec::new();
    if let Err(e) = tls_stream.read_to_end(&mut response) {
        return Err(format!("Failed to read response: {}", e));
    }
    
    // Parse Gemini response
    parse_gemini_response(&response)
}

/// Parse Gemini response according to the protocol
fn parse_gemini_response(response: &[u8]) -> Result<String, String> {
    // Find the CRLF that separates header from body
    let crlf_pos = find_crlf(response);
    if crlf_pos.is_none() {
        return Err("Invalid response format: missing CRLF".to_string());
    }
    
    let header_end = crlf_pos.unwrap() + 2;
    let header_bytes = &response[..header_end];
    let body_bytes = &response[header_end..];
    
    // Parse status line (first line of header)
    let header_str = match std::str::from_utf8(header_bytes) {
        Ok(s) => s,
        Err(_) => return Err("Invalid UTF-8 in response header".to_string()),
    };
    
    let status_line = header_str.lines().next().unwrap_or("");
    let parts: Vec<&str> = status_line.split_whitespace().collect();
    
    if parts.len() < 2 {
        return Err("Invalid status line format".to_string());
    }
    
    let status_code = parts[0];
    let meta = if parts.len() > 2 { parts[2..].join(" ") } else { "".to_string() };
    
    // Check status code
    match status_code {
        "20" => {
            // Success - return the body content
            let body_str = match std::str::from_utf8(body_bytes) {
                Ok(s) => s,
                Err(_) => return Err("Invalid UTF-8 in response body".to_string()),
            };
            Ok(format!("Status: {} - {}\n\n{}", status_code, meta, body_str))
        },
        "30" => {
            // Redirect
            Err(format!("Redirect ({}): {}", status_code, meta))
        },
        "40" => {
            // Temporary failure
            Err(format!("Temporary failure ({}): {}", status_code, meta))
        },
        "50" => {
            // Permanent failure
            Err(format!("Permanent failure ({}): {}", status_code, meta))
        },
        "60" => {
            // Client certificate required
            Err(format!("Client certificate required ({}): {}", status_code, meta))
        },
        _ => {
            // Unknown status code
            Err(format!("Unknown status code: {} - {}", status_code, meta))
        }
    }
}

/// Find CRLF sequence in byte array
fn find_crlf(data: &[u8]) -> Option<usize> {
    let crlf = b"\r\n";
    data.windows(crlf.len()).position(|window| window == crlf)
}
