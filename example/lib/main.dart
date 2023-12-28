import 'package:flutter/material.dart';
import 'package:pinch_to_zoom_scrollable/pinch_to_zoom_scrollable.dart';
import 'package:pinch_to_zoom_scrollable_example/gen/assets.gen.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinch to zoom_scrollable example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Pinch to zoom scrollable example'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    _controller = VideoPlayerController.asset(Assets.catVideo)
      ..setLooping(true)
      ..initialize().then((_) {
        //setState(() {});
        _controller.play();
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          _statefulItem(title: "I save state", saveState: true),
          _statefulItem(title: "I don't", saveState: false),
          _videoItem(),
          _imageItem(Assets.cat1),
          _imageItem(Assets.cat2),
          _imageItem(Assets.cat3),
          _imageItem(Assets.cat4),
          _imageItem(Assets.cat5),
          _imageItem(Assets.cat6),
          const SizedBox(
            height: 16,
          )
        ],
      ),
    );
  }

  Widget _statefulItem({required String title, required bool saveState}) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        // When using the 'saveState' property, it is necessary to set
        // size before the PinchToZoomScrollableWidget
        // because the child widget will be fully moved into the Overlay.
        child: SizedBox(
          height: 100,
          child: PinchToZoomScrollableWidget(
            child: SomeStatefulWidget(title: title),
            saveState: saveState,
          ),
        ),
      ),
    );
  }

  Widget _videoItem() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PinchToZoomScrollableWidget(
          child: AspectRatio(
            aspectRatio: 1.6,
            child: VideoPlayer(
              _controller,
            ),
          ),
          //useGlobalKey: true,
        ),
      ),
    );
  }

  Widget _imageItem(AssetGenImage image) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: PinchToZoomScrollableWidget(
          child: Image.asset(image.path),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class SomeStatefulWidget extends StatefulWidget {
  final String title;

  const SomeStatefulWidget({required this.title, super.key});

  @override
  State<SomeStatefulWidget> createState() => _SomeStatefulWidgetState();
}

class _SomeStatefulWidgetState extends State<SomeStatefulWidget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text("${widget.title}\ncount = $counter"),
        ),
      ),
      onTap: () {
        setState(() {
          counter++;
        });
      },
    );
  }
}
