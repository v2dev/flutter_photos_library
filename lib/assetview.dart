import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'asset.dart';
import 'photos_library.dart';

class AssetView extends StatefulWidget {
  final int index;
  final Asset asset;
  final double width;
  final double height;
  AssetView(
      {@required this.index, @required this.asset, @required this.width, @required this.height});

  @override
  State<StatefulWidget> createState() => AssetState(
      index: this.index,
      asset: this.asset,
      width: this.width,
      height: this.height);
}

class AssetState extends State<AssetView> {
  int index = 0;
  Asset asset;
  final double width;
  final double height;

  ByteData _imageData;
  String _channelName;

  AssetState(
      {@required this.index, @required this.asset, @required this.width, @required this.height}) {
    const prefix = 'flutter.yang.me/photos_library/image';
    this._channelName = prefix + '/' + this.asset.identifier;
  }

  @override
  void initState() {
    super.initState();

    this._requestThumbnail(
        width: this.width.toInt(), height: this.height.toInt());
  }

  @override
  void deactivate() {
    super.deactivate();
    BinaryMessages.setMessageHandler(this._channelName, null);
  }

  void _requestThumbnail({int width, int height}) {
//    BinaryMessages.setMessageHandler(this._channelName, (message) {
//      this._imageData = message;
//      setState(() {});
//    });
//
//    PhotosLibrary.requestThumbnail(this.asset.identifier, width, height);
//    print("Vidoe Path ");
//
//    print(PhotosLibrary.requestVideoPath(this.asset.identifier, width, height));

  print(PhotosLibrary.testMethod(this.asset.identifier, width, height));





  }

  @override
  Widget build(BuildContext context) {
    if (null != this._imageData) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 2000),
        child: Image.memory(
          this._imageData.buffer.asUint8List(),
          fit: BoxFit.cover,
          width: this.width,
          height: this.height,
        ),
        key: ValueKey<ByteData>(this._imageData),
      );
    }

    return Text(
      '${this.index}',
      style: Theme.of(context).textTheme.headline,
    );
  }
}
