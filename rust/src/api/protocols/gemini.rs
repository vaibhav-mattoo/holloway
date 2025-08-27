use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::Duration;
use native_tls::TlsConnector;

/// Connect to Gemini server and fetch content
pub async fn connect_and_fetch_gemini(host: &str, port: u16, url: &str) -> Result<String, String> {
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

