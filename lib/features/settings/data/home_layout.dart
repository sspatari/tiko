class HomeLayout {
  const HomeLayout({
    this.compact = false,
    this.pinnedIds = const [],
    this.order = const [],
  });
  final bool compact;
  final List<String> pinnedIds;
  final List<String> order;

  HomeLayout copyWith({
    bool? compact,
    List<String>? pinnedIds,
    List<String>? order,
  }) => HomeLayout(
    compact: compact ?? this.compact,
    pinnedIds: List.unmodifiable(pinnedIds ?? this.pinnedIds),
    order: List.unmodifiable(order ?? this.order),
  );

  Map<String, Object> toJson() => {
    'compact': compact,
    'pinnedIds': pinnedIds,
    'order': order,
  };

  factory HomeLayout.fromJson(Map<String, dynamic> data) {
    if (data.containsKey('compact') && data['compact'] is! bool) {
      throw const FormatException('Invalid Home layout');
    }
    List<String> ids(String key) {
      final value = data[key];
      if (!data.containsKey(key)) return const [];
      if (value is! List || value.any((id) => id is! String || id.isEmpty)) {
        throw const FormatException('Invalid Home subscription IDs');
      }
      final result = value.cast<String>();
      if (result.toSet().length != result.length) {
        throw const FormatException('Duplicate Home subscription IDs');
      }
      return List.unmodifiable(result);
    }

    return HomeLayout(
      compact: data['compact'] as bool? ?? false,
      pinnedIds: ids('pinnedIds'),
      order: ids('order'),
    );
  }
}
