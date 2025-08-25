use url::Url;

/// Navigate to a Gemini, Gopher, or Finger URL and return the plaintext content
pub async fn navigate_internal(url: String) -> Result<String, String> {
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
            match crate::api::protocols::gemini::connect_and_fetch_gemini(host, port, &url).await {
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
            match crate::api::protocols::gopher::connect_and_fetch_gopher(host, port, parsed_url.path()).await {
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
            match crate::api::protocols::finger::connect_and_fetch_finger(host, port, &username).await {
                Ok(content) => Ok(content),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        }
        _ => Err("Only gemini://, gopher://, and finger:// URLs are supported".to_string()),
    }
}
