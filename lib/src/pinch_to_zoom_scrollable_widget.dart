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
  const PinchToZoomScrollableWidget({required this.child,
    this.resetDuration = defaultResetDuration,
    this.resetCurve = Curves.ease,
    this.clipBehavior = Clip.none,
    this.maxScale = 8,
    this.overlayColor = defaultColorOverlay,
    this.saveState = false,
    super.key})
      : assert(maxScale > 0);

  /// Widget for zooming
  final Widget child;

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

  @override
  State<PinchToZoomScrollableWidget> createState() =>
      _PinchToZoomScrollableWidgetState();
}

/// State of PinchToZoomScrollableWidget
class _PinchToZoomScrollableWidgetState
    extends State<PinchToZoomScrollableWidget>
    with TickerProviderStateMixin {
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
            Future.delayed(const Duration(milliseconds: 100), removeOverlay);
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
      Overlay.of(context);
      return entry == null
          ? buildWidget(zoomableWidget: widget.child)
          : const SizedBox();
    } else {
      return buildWidget(zoomableWidget: widget.child);
    }
  }

  void resetAnimation() {
    _animation = Matrix4Tween(begin: _controller.value, end: Matrix4.identity())
        .animate(CurvedAnimation(
        parent: _animationController!, curve: widget.resetCurve));
    _animationController!.forward(from: 0);
  }

  Widget buildWidget({required Widget zoomableWidget}) =>
      Builder(
        key: widget.saveState ? _key : null,
        builder: (context) {
          if (widget.saveState) {
            Overlay.of(context);
          }

          return InsistentInteractiveViewer(
            clipBehavior: widget.clipBehavior,
            maxScale: widget.maxScale,
            transformationController: _controller,
            onInteractionStart: _onInteractionStart,
            onInteractionEnd: _onInteractionEnd,
            panEnabled: false,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: zoomableWidget,
          );
        },
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
    final OverlayState overlay = Overlay.of(context);
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Widget zoomWidget = buildWidget(zoomableWidget: widget.child);

    entry = OverlayEntry(
        builder: (context) =>
            _buildOverlayBody(context, renderBox, offset, zoomWidget));

    setState(() {});
    Future(() {
      overlay.insert(entry!);
      // We need to control all the overlays added
      // to avoid problems in scaling,
      overlayEntries.add(entry!);
    });
  }

  Widget _buildOverlayBody(BuildContext context, RenderBox renderBox,
      Offset offset, Widget zoomWidget) =>
      Material(
        color: Colors.green.withOpacity(0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: widget.overlayColor),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: SizedBox(
                width: renderBox.size.width,
                height: renderBox.size.height,
                child: zoomWidget,
              ),
            ),
          ],
        ),
      );

  void removeOverlay() {
    for (final entry in overlayEntries) {
      entry.remove();
    }
    overlayEntries.clear();
    entry = null;
    if (widget.saveState) {
      setState(() {});
    }
  }
}
