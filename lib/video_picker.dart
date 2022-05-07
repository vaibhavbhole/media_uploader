import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:images_picker/images_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class VideoPickerExample extends StatefulWidget {
  @override
  _VideoPickerExampleState createState() => _VideoPickerExampleState();
}

class _VideoPickerExampleState extends State<VideoPickerExample> {
  final picker = ImagePicker();
  bool _uploading = false;
  double _uploadingPercentage = 0.0;
  String? path;
  Subscription? _subscription;
  double? _progress;

  final cloudinary = CloudinaryPublic(
    'dagama',
    // See https://cloudinary.com/documentation/upload_images#unsigned_upload on to create an upload preset
    'vkcgfwz0',
    cache: false,
  );
  VideoPlayerController? _videoPlayerController;
  Future getVideo() async {
    print("Inside");
    path = null;
    _videoPlayerController?.dispose();
    List<Media>? res = await ImagesPicker.openCamera(
      // pickType: PickType.video,
      pickType: PickType.video,
      quality: 0.1,
      maxSize: 8000,
      // cropOpt: CropOption(
      //   aspectRatio: CropAspectRatio.wh16x9,
      // ),
      maxTime: 30,
    );
    print(res);
    if (res != null) {
      print("path: " + res[0].path);
      setState(() {
        path = res[0].path;
      });
    }

//    final video = await picker.pickVideo(source: ImageSource.camera,maxDuration: Duration(seconds: 30));
    //final video = await picker.pickVideo(source: ImageSource.camera);

    // setState(() {
    //   if (video != null) {
    //     _pickedFile = PickedFile(video.path);
    //   } else {
    //     print('No image selected.');
    //   }
    // });
    //debugPrint("Picked file: ${File(_pickedFile!.path).path}");
    // _videoPlayerController = VideoPlayerController.file(File(_pickedFile!.path))..initialize().then((_) {
    //   setState(() { });
    //   _videoPlayerController?.play();
    // });

    _videoPlayerController = VideoPlayerController.file(File(path.toString()));
    _videoPlayerController!.addListener(() {
      setState(() {});
    });
    _videoPlayerController!.setLooping(true);
    _videoPlayerController!.initialize().then((value) {
      print("inside videoController intialize");
      setState(() {
        _videoPlayerController!.play();
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      debugPrint('progress: $progress');
      setState(() {
        _progress = progress;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _videoPlayerController?.dispose();
    _subscription?.unsubscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Picker Example'),
      ),
      body: Center(child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: getVideo,
        tooltip: 'Pick Video',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildBody() {
    if (path == null) return Text('No video selected.');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildVideo()),
        if (_progress != null) Text("Compressing: $_progress"),
        TextButton(
          onPressed: _uploading ? null : _upload,
          child: _uploading
              ? Text('${_uploadingPercentage.toStringAsFixed(2)}%')
              : Text('Upload'),
        ),
      ],
    );
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    try {
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        path!,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false, // It's false by default
      );
      setState(() {
        _progress = null;
      });
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          mediaInfo!.path!,
          folder: 'hello-folder',
          context: {
            'alt': 'Hello',
            'caption': 'An example video',
          },
        ),
        onProgress: (count, total) {
          setState(() {
            _uploadingPercentage = (count / total) * 100;
          });
        },
      );
      print(res);
    } on CloudinaryException catch (e) {
      print(e.message);
      print(e.request);
    }

    setState(() {
      _uploading = false;
      _uploadingPercentage = 0.0;
    });
  }

  Widget _buildVideo() {
    return _videoPlayerController!.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          )
        : Container();
  }
}
