import 'package:flutter/material.dart';
import 'package:photos_library/photos_library.dart';
import 'package:photos_library/asset.dart';
import 'package:photos_library/assetview.dart';

class HomeView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<HomeView> {
  final _assets = List<Asset>();
  bool _firstRun = true;
  PhotosLibraryAuthorizationStatus _status =
      PhotosLibraryAuthorizationStatus.NotDetermined;

  Widget buildStatus(BuildContext context) {
    String statusString = "Unknown status";
    switch (_status) {
      case PhotosLibraryAuthorizationStatus.Authorized:
        statusString = "Authorized";
        break;
      case PhotosLibraryAuthorizationStatus.Denied:
        statusString = "Denied";
        break;
      case PhotosLibraryAuthorizationStatus.NotDetermined:
        statusString = "Not Determined";
        break;
      default:
        statusString = "Undefined";
    }

    return Text(statusString);
  }

  @override
  void initState() {
    super.initState();
    refreshStatus();
  }

  void refreshStatus() async {
    try {
      var status = await PhotosLibrary.authorizeationStatus;
      print("status: $status");
      setState(() {
        this._status = status;
      });
    } catch (e) {}
  }

  void requestAuthorization() async {
    try {
      var status = await PhotosLibrary.requestAuthorization;
      setState(() {
        this._status = status;
      });
    } catch (e) {}
  }

  void loadAssets() async {
    try {
      var assets =
          await PhotosLibrary.fetchMediaWithType(PhotosLibraryMediaType.Video);
      setState(() {
        this._assets.clear();
        this._assets.addAll(assets);
      });
    } catch (e) {}
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(_assets.length, (index) {
        return AssetView(
            index: index, asset: _assets[index], width: 1000.0, height: 1000.0);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_firstRun) {
      refreshStatus();
      _firstRun = false;
    }
    return Column(
      children: <Widget>[
        Center(
          child: Text("Photos Library Authorization status:"),
        ),
        Center(child: buildStatus(context)),
        RaisedButton(
          child: Text("Authorize"),
          onPressed: requestAuthorization,
        ),
        RaisedButton(
          child: Text("Load Assets"),
          onPressed: loadAssets,
        ),
        Expanded(
          child: buildGridView(),
        )
      ],
    );
  }
}
