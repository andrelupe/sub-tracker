/// Stub implementation for non-web platforms.
/// On native platforms, file export uses the file system directly.
void downloadFile(String content, String filename) {
  // No-op on non-web platforms.
  // Native export could use path_provider + file system in the future.
}
