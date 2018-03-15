library cached_network_image;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show instantiateImageCodec, Codec;

import 'package:fancy_network_image/fancy_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/**
 *  CachedNetworkImage for Flutter
 *
 *  Copyright (c) 2017 Rene Floor
 *
 *  Released under MIT License.
 */

class CachedNetworkImage extends FancyNetworkImage {
  /// Creates a widget that displays a [placeholder] while an [imageUrl] is loading
  /// then cross-fades to display the [imageUrl].
  ///
  /// The [imageUrl], [fadeOutDuration], [fadeOutCurve],
  /// [fadeInDuration], [fadeInCurve], [alignment], [repeat], and
  /// [matchTextDirection] arguments must not be null. Arguments [width],
  /// [height], [fit], [alignment], [repeat] and [matchTextDirection]
  /// are only used for the image and not for the placeholder.
  const CachedNetworkImage({
    Key key,
    @required String imageUrl,
    Widget placeholder,
    Widget errorWidget,
    Duration fadeOutDuration: const Duration(milliseconds: 300),
    Curve fadeOutCurve: Curves.easeOut,
    Duration fadeInDuration: const Duration(milliseconds: 700),
    Curve fadeInCurve: Curves.easeIn,
    double width,
    double height,
    BoxFit fit,
    Alignment alignment: Alignment.center,
    ImageRepeat repeat: ImageRepeat.noRepeat,
    bool matchTextDirection: false,
    double scale: 1.0,
    Map<String, String> headers,
  })
      : super(
          key: key,
          imageUrl: imageUrl,
          placeholder: placeholder,
          errorWidget: errorWidget,
          fadeOutDuration: fadeOutDuration,
          fadeInDuration: fadeInDuration,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          repeat: repeat,
          matchTextDirection: matchTextDirection,
          scale: scale,
          headers: headers,
        );

  @override
  State<StatefulWidget> createState() => new _CachedNetworkImageState();
}

class _CachedNetworkImageState extends FancyNetworkImageState {
  @override
  FancyNetworkImageProvider createProvider(
      String url, ErrorListener errorListener,
      {double scale: 1.0, Map<String, String> headers}) {
    return new CachedNetworkImageProvider(
      url,
      errorListener: errorListener,
      scale: scale,
      headers: headers,
    );
  }
}

class CachedNetworkImageProvider extends FancyNetworkImageProvider {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const CachedNetworkImageProvider(
    String url, {
    double scale: 1.0,
    ErrorListener errorListener,
    Map<String, String> headers,
  })
      : super(
          url,
          scale: scale,
          errorListener: errorListener,
          headers: headers,
        );

  @override
  Future<CachedNetworkImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return new SynchronousFuture<CachedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(NetworkImage key) {
    return new MultiFrameImageStreamCompleter(
        codec: _loadAsync(key),
        scale: key.scale,
        informationCollector: (StringBuffer information) {
          information.writeln('Image provider: $this');
          information.write('Image key: $key');
        });
  }

  Future<ui.Codec> _loadAsync(NetworkImage key) async {
    var cacheManager = await CacheManager.getInstance();
    try {
      var file = await cacheManager.getFile(url);
      return _loadAsyncFromFile(key, file);
    } catch (e) {
      errorListener();

      throw new Exception('Could not load image at url: $url');
    }
  }

  Future<ui.Codec> _loadAsyncFromFile(
      CachedNetworkImageProvider key, File file) async {
    assert(key == this);

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes == 0) return null;

    return await ui.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final CachedNetworkImageProvider typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
