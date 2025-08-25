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
    crate::api::functions::navigate_internal::navigate_internal(url).await
}

/// Get the default start page URL
#[flutter_rust_bridge::frb(sync)]
pub fn get_start_page() -> String {
    "gemini://gemini.circumlunar.space/".to_string()
}