import 'package:flutter/widgets.dart';

/// Like [StreamBuilder], but [create] runs exactly once (in [initState]) and
/// only runs again if [keys] changes between rebuilds - never on a rebuild
/// that leaves [keys] the same.
///
/// Building the stream inline inside `build()` (eg.
/// `StreamBuilder(stream: Service.getXStream(id), ...)`) makes a brand new
/// subscription every time the widget rebuilds, because most stream-returning
/// service methods call `.snapshots()`/`.map()` fresh each call. Framework-
/// driven rebuilds happen far more often than "the underlying data actually
/// changed" - a parent's unrelated setState, or an iOS back-swipe gesture
/// rebuilding the route underneath it even when the gesture is never
/// completed - so that pattern makes the page flash back to its loading
/// state on any of those, not just on a real data change.
class CachedStreamBuilder<T> extends StatefulWidget {
  final Stream<T> Function() create;
  final AsyncWidgetBuilder<T> builder;

  /// Recreate the stream only when this changes (compared with [==] on each
  /// element). Leave as the default `const []` when the source doesn't
  /// depend on anything that changes over the widget's lifetime.
  final List<Object?> keys;

  const CachedStreamBuilder({
    super.key,
    required this.create,
    required this.builder,
    this.keys = const [],
  });

  @override
  State<CachedStreamBuilder<T>> createState() =>
      _CachedStreamBuilderState<T>();
}

class _CachedStreamBuilderState<T> extends State<CachedStreamBuilder<T>> {
  late Stream<T> _stream;
  late List<Object?> _keys;

  @override
  void initState() {
    super.initState();
    _stream = widget.create();
    _keys = widget.keys;
  }

  @override
  void didUpdateWidget(covariant CachedStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameKeys(_keys, widget.keys)) {
      _stream = widget.create();
      _keys = widget.keys;
    }
  }

  bool _sameKeys(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(stream: _stream, builder: widget.builder);
  }
}

/// [Future] counterpart of [CachedStreamBuilder] - see its doc comment for
/// why this matters. `Future.value`-returning service calls made inline in
/// `build()` re-run on every rebuild the same way inline streams do.
class CachedFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() create;
  final AsyncWidgetBuilder<T> builder;
  final List<Object?> keys;

  const CachedFutureBuilder({
    super.key,
    required this.create,
    required this.builder,
    this.keys = const [],
  });

  @override
  State<CachedFutureBuilder<T>> createState() =>
      _CachedFutureBuilderState<T>();
}

class _CachedFutureBuilderState<T> extends State<CachedFutureBuilder<T>> {
  late Future<T> _future;
  late List<Object?> _keys;

  @override
  void initState() {
    super.initState();
    _future = widget.create();
    _keys = widget.keys;
  }

  @override
  void didUpdateWidget(covariant CachedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameKeys(_keys, widget.keys)) {
      _future = widget.create();
      _keys = widget.keys;
    }
  }

  bool _sameKeys(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(future: _future, builder: widget.builder);
  }
}
