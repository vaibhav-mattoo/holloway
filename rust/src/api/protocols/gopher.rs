use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::time::Duration;

/// Connect to Gopher server and fetch content
pub async fn connect_and_fetch_gopher(host: &str, port: u16, path: &str) -> Result<String, String> {
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

