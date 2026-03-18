class SystemNotificationSound {
  const SystemNotificationSound({
    required this.uri,
    required this.label,
    this.isDefault = false,
  });

  final String uri;
  final String label;
  final bool isDefault;
}
