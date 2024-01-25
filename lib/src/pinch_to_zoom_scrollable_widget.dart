// ignore_for_file: prefer_asserts_with_message

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinch_to_zoom_scrollable/src/insistent_interactive_viewer.dart';

class PinchToZoomScrollableWidget extends StatefulWidget {
  static const Duration defaultResetDuration = Duration(milliseconds: 200);
  static const Color defaultColorOverlay = Colors.black26;

  /// Create an PinchToZoomScrollableWidget,
  /// it is just a customization over an interactive viewer fork
  ///
  /// * [child] is the widget used for zooming.
  /// This parameter is required
  /// because without a child there is nothing to zoom on
  const PinchToZoomScrollableWidget({
    required this.child,
    this.zoomChild,
    this.resetDuration = defaultResetDuration,
    this.resetCurve = Curves.ease,
    this.clipBehavior = Clip.none,
    this.maxScale = 8,
    this.overlayColor = defaultColorOverlay,
    this.saveState = false,
    this.rootOverlay = false,
    super.key,
  }) : assert(maxScale > 0);

  /// Widget for zooming
  final Widget child;

  /// Widget for zooming
  final Widget? zoomChild;

  /// If set to [Clip.none], the child may extend beyond
  /// the size of the InteractiveViewer,
  /// but it will not receive gestures in these areas.
  /// Be sure that the InteractiveViewer is the desired size
  /// when using [Clip.none].
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The maximum allowed scale.
  /// Defaults to 8.
  final double maxScale;

  /// The duration of the reset animation
  final Duration resetDuration;

  /// The curve of the reset animation
  final Curve resetCurve;

  /// Overlay color
  final Color overlayColor;

  /// Use [GlobalKey] for the container
  /// that holds the [PinchToZoomScrollableWidget.child].
  /// It is useful for saving the state
  /// of the [PinchToZoomScrollableWidget.child] (ex for VideoPlayer).
  final bool saveState;

  /// If `rootOverlay` is set to true, the state from the furthest instance of
  /// this class is given instead. Useful for installing overlay entries above
  /// all subsequent instances of [Overlay].
  final bool rootOverlay;

  @override
  State<PinchToZoomScrollableWidget> createState() =>
      _PinchToZoomScrollableWidgetState();
}

/// State of PinchToZoomScrollableWidget
class _PinchToZoomScrollableWidgetState
    extends State<PinchToZoomScrollableWidget> with TickerProviderStateMixin {
  /// A thin wrapper on [ValueNotifier] whose value is a [Matrix4]
  /// representing a transformation of [InsistentInteractiveViewer].
  late final _controller = InsistentTransformationController();

  /// Reset animation controller
  AnimationController? _animationController;

  /// Reset animation
  // ignore: use_late_for_private_fields_and_variables
  Animation<Matrix4>? _animation;

  /// OverlayEntry for pinched [PinchToZoomScrollableWidget.child]
  OverlayEntry? entry;

  List<OverlayEntry> overlayEntries = [];

  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initAnimationController();
  }

  @override
  void didUpdateWidget(covariant PinchToZoomScrollableWidget oldWidget) {
    if (oldWidget.resetDuration != widget.resetDuration) {
      _initAnimationController();
    } else if (oldWidget.zoomChild != widget.zoomChild && entry != null) {
      // zoomWidget have changed while it was displayed
      removeOverlay();
      _showOverlay(context);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initAnimationController() {
    _animationController?.dispose();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.resetDuration,
    )
      ..addListener(
        () {
          _controller.value = _animation!.value;
        },
      )
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            removeOverlay();
          }
        },
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.saveState) {
      return entry == null
          ? buildWidget(child: widget.child)
          : const SizedBox();
    } else {
      return buildWidget(child: widget.child);
    }
  }

  void resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: widget.resetCurve,
      ),
    );
    _animationController!.forward(from: 0);
  }

  Widget buildWidget({required Widget child}) => Builder(
        key: widget.saveState ? _key : null,
        builder: (context) => InsistentInteractiveViewer(
          clipBehavior: widget.clipBehavior,
          maxScale: widget.maxScale,
          transformationController: _controller,
          onInteractionStart: _onInteractionStart,
          onInteractionEnd: _onInteractionEnd,
          panEnabled: false,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: child,
        ),
      );

  void _onInteractionStart(ScaleStartDetails details) {
    // avoided start with ScaleStartDetails.pointerCount fingers
    if (details.pointerCount != 2) {
      return;
    }
    _animationController!.stop();
    if (entry == null) {
      _showOverlay(context);
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (overlayEntries.isEmpty) {
      return;
    }
    resetAnimation();
  }

  void _showOverlay(BuildContext context) {
    final OverlayState overlay = Overlay.of(
      context,
      rootOverlay: widget.rootOverlay,
    );
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final Offset offset = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay.context.findRenderObject(),
    );
    final Widget child = buildWidget(
      child: widget.zoomChild ?? widget.child,
    );

    entry = OverlayEntry(
      builder: (context) => _buildOverlayBody(
        context,
        renderBox,
        offset,
        child,
      ),
    );

    setState(() {});
    Future(() {
      overlay.insert(entry!);
      // We need to control all the overlays added
      // to avoid problems in scaling,
      overlayEntries.add(entry!);
    });
  }

  Widget _buildOverlayBody(
    BuildContext context,
    RenderBox renderBox,
    Offset offset,
    Widget child,
  ) =>
      Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(color: widget.overlayColor),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: SizedBox(
                width: renderBox.size.width,
                height: renderBox.size.height,
                child: child,
              ),
            ),
          ],
        ),
      );

  void removeOverlay() {
    for (final OverlayEntry entry in overlayEntries) {
      entry
        ..remove()
        ..dispose();
    }
    overlayEntries.clear();
    entry = null;
    if (widget.saveState) {
      setState(() {});
    }
  }
}
