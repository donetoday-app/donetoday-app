class ClientConfig {
  static const String gitHubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: '', // public release repo
  );
}
