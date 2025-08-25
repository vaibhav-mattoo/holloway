use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::Duration;

/// Connect to Finger server and fetch content
pub async fn connect_and_fetch_finger(host: &str, port: u16, username: &str) -> Result<String, String> {
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
