import 'package:flutter/widgets.dart';

class InfiniteScrollListener extends StatelessWidget {
  const InfiniteScrollListener({
    super.key,
    required this.child,
    required this.onEndReached,
    this.isLoading = false,
    this.hasMore = true,
    this.endOffset = 240,
  });

  final Widget child;
  final VoidCallback onEndReached;
  final bool isLoading;
  final bool hasMore;
  final double endOffset;

  bool _isNearEnd(ScrollMetrics metrics) {
    if (!metrics.hasPixels || !metrics.hasContentDimensions) return false;
    final remaining = metrics.maxScrollExtent - metrics.pixels;
    return remaining <= endOffset;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isLoading || !hasMore) return false;
        final metrics = notification.metrics;
        if (_isNearEnd(metrics)) {
          onEndReached();
        }
        return false;
      },
      child: child,
    );
  }
}

