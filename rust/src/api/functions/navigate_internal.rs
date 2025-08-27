use url::Url;

/// Navigate to a Gemini, Gopher, or Finger URL and return the plaintext content
pub async fn navigate_internal(url: String) -> Result<String, String> {
    // Try to parse the URL as-is first
    let parsed_url = match Url::parse(&url) {
        Ok(url) => url,
        Err(_) => {
            // If parsing fails, try adding gemini:// prefix
            let gemini_url = format!("gemini://{}", url);
            match Url::parse(&gemini_url) {
                Ok(url) => url,
                Err(_) => {
                    // If both fail, try the final fallback with kennedy.gemi.dev
                    let fallback_url = format!("gemini://kennedy.gemi.dev/search?{}", url);
                    match crate::api::protocols::gemini::connect_and_fetch_gemini(
                        "kennedy.gemi.dev",
                        1965,
                        &fallback_url,
                    )
                    .await
                    {
                        Ok(content) => return Ok(content),
                        Err(_) => return Err("Invalid URL format".to_string()),
                    }
                }
            }
        }
    };

    // Now check the scheme of the parsed URL
    match parsed_url.scheme() {
        "gemini" => {
            let host = match parsed_url.host_str() {
                Some(h) => h,
                None => return Err("Invalid host in URL".to_string()),
            };
            let port = parsed_url.port().unwrap_or(1965);

            // Normalize the URL for Gemini requests - ensure it has a trailing slash if no path
            let mut request_url = if url.starts_with("gemini://") {
                url.clone()
            } else {
                format!("gemini://{}", url)
            };

            // If the URL doesn't have a path or ends with just the host, add a trailing slash
            if !request_url.contains('/') || request_url.ends_with(&host) {
                request_url.push('/');
            }

            // Try the original request first
            match crate::api::protocols::gemini::connect_and_fetch_gemini(host, port, &request_url)
                .await
            {
                Ok(content) => Ok(content),
                Err(_) => {
                    // If the original request fails, try with the fallback URL format
                    let fallback_url = format!("gemini://kennedy.gemi.dev/search?{}", url);
                    match crate::api::protocols::gemini::connect_and_fetch_gemini(
                        "kennedy.gemi.dev",
                        1965,
                        &fallback_url,
                    )
                    .await
                    {
                        Ok(content) => Ok(content),
                        Err(e) => Err(format!("Failed to fetch {}: {}", request_url, e)),
                    }
                }
            }
        }
        "gopher" => {
            let host = match parsed_url.host_str() {
                Some(h) => h,
                None => return Err("Invalid host in URL".to_string()),
            };
            let port = parsed_url.port().unwrap_or(70);
            match crate::api::protocols::gopher::connect_and_fetch_gopher(
                host,
                port,
                parsed_url.path(),
            )
            .await
            {
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
            match crate::api::protocols::finger::connect_and_fetch_finger(host, port, &username)
                .await
            {
                Ok(content) => Ok(content),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        }
        _ => Err(
            "Unsupported URL scheme. Only gemini, gopher, and finger are supported.".to_string(),
        ),
    }
}
