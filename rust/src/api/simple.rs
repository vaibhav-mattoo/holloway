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

/// Navigate to a Gemini, Gopher, or Finger URL and return the plaintext content
#[flutter_rust_bridge::frb]
pub async fn navigate(url: String) -> Result<String, String> {
    // Parse the URL to validate it
    let parsed_url = match Url::parse(&url) {
        Ok(url) => url,
        Err(_) => return Err("Invalid URL format".to_string()),
    };

    match parsed_url.scheme() {
        "gemini" => {
            let host = match parsed_url.host_str() {
                Some(h) => h,
                None => return Err("Invalid host in URL".to_string()),
            };
            let port = parsed_url.port().unwrap_or(1965);
            match connect_and_fetch_gemini(host, port, &url).await {
                Ok(content) => Ok(content),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        }
        "gopher" => {
            let host = match parsed_url.host_str() {
                Some(h) => h,
                None => return Err("Invalid host in URL".to_string()),
            };
            let port = parsed_url.port().unwrap_or(70);
            match connect_and_fetch_gopher(host, port, parsed_url.path()).await {
                Ok(content) => Ok(content),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        }
        "finger" => {
            let host = match parsed_url.host_str() {
                Some(h) => h,
                None => return Err("Invalid host in URL".to_string()),
            };
            let port = parsed_url.port().unwrap_or(79);
            let username = if parsed_url.username().is_empty() {
                parsed_url.path().trim_start_matches('/').to_string()
            } else {
                parsed_url.username().to_string()
            };
            match connect_and_fetch_finger(host, port, &username).await {
                Ok(content) => Ok(content),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        }
        _ => Err("Only gemini://, gopher://, and finger:// URLs are supported".to_string()),
    }
}

/// Get the default start page URL
#[flutter_rust_bridge::frb(sync)]
pub fn get_start_page() -> String {
    "gemini://gemini.circumlunar.space/".to_string()
}

/// Connect to Gemini server and fetch content
async fn connect_and_fetch_gemini(host: &str, port: u16, url: &str) -> Result<String, String> {
    // Create socket address
    let socket_addr = format!("{}:{}", host, port);

    // Connect TCP stream using ToSocketAddrs trait
    let tcp_stream = match socket_addr.to_socket_addrs() {
        Ok(mut addrs_iter) => match addrs_iter.next() {
            Some(addr) => match TcpStream::connect_timeout(&addr, Duration::new(10, 0)) {
                Ok(stream) => stream,
                Err(e) => return Err(format!("TCP connection failed: {}", e)),
            },
            None => return Err("No socket addresses found".to_string()),
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

    // For simplicity, we are not parsing the Gemini header and just returning the body.
    // A proper implementation should parse the header and handle different status codes.
    let body_start = match response.windows(2).position(|w| w == b"\r\n") {
        Some(pos) => pos + 2,
        None => 0, // No header found, assume entire response is body
    };

    Ok(String::from_utf8_lossy(&response[body_start..]).to_string())
}

/// Connect to Gopher server and fetch content
async fn connect_and_fetch_gopher(host: &str, port: u16, path: &str) -> Result<String, String> {
    let socket_addr = format!("{}:{}", host, port);

    let mut stream = match TcpStream::connect_timeout(
        &socket_addr
            .to_socket_addrs()
            .map_err(|e| e.to_string())?
            .next()
            .ok_or_else(|| "No addresses found".to_string())?,
        Duration::new(10, 0),
    ) {
        Ok(s) => s,
        Err(e) => return Err(e.to_string()),
    };

    stream
        .write_all(format!("{}\r\n", path).as_bytes())
        .map_err(|e| e.to_string())?;

    let mut response = Vec::new();
    stream
        .read_to_end(&mut response)
        .map_err(|e| e.to_string())?;

    Ok(String::from_utf8_lossy(&response).to_string())
}

/// Connect to Finger server and fetch content
async fn connect_and_fetch_finger(host: &str, port: u16, username: &str) -> Result<String, String> {
    let socket_addr = format!("{}:{}", host, port);

    let mut stream = match TcpStream::connect_timeout(
        &socket_addr
            .to_socket_addrs()
            .map_err(|e| e.to_string())?
            .next()
            .ok_or_else(|| "No addresses found".to_string())?,
        Duration::new(10, 0),
    ) {
        Ok(s) => s,
        Err(e) => return Err(e.to_string()),
    };

    // Send finger request: username + CRLF
    let request = format!("{}\r\n", username);
    stream
        .write_all(request.as_bytes())
        .map_err(|e| e.to_string())?;

    let mut response = Vec::new();
    stream
        .read_to_end(&mut response)
        .map_err(|e| e.to_string())?;

    Ok(String::from_utf8_lossy(&response).to_string())
}