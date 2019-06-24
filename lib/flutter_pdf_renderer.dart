import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class FlutterPdfRenderer {
  static const MethodChannel _channel =
  MethodChannel('rackberg.flutter_pdf_renderer');

  /// Sends the [pdfFile] to the platform which then renders it.
  static Future<List<File>> renderPdf({String pdfFile}) async {
    final result =
    await _channel.invokeMethod('renderPdf', <String, dynamic>{
      'path': pdfFile,
    });

    List<File> files = [];
    if (result.length > 0) {
      result.forEach((r) {
        files.add(File(r));
      });
    }

    return files;
  }
}

/// Displays the pages of a [pdfFile] stored on the device.
class PdfRenderer extends StatefulWidget {
  final String pdfFile;
  final double width;
  final double maxZoom;
  final double minZoom;

  PdfRenderer({this.pdfFile, this.width, this.maxZoom = 3.0, this.minZoom = 1.0});

  @override
  State<StatefulWidget> createState() => _PdfRendererState();
}

class _PdfRendererState extends State<PdfRenderer> {
  List<File> files;

  /// State for zoom event
  double _scale = 1.0;
  double _previousScale = null;

  void _renderPdf() async {
    final result = await FlutterPdfRenderer.renderPdf(pdfFile: widget.pdfFile);
    setState(() {
      files = result;
    });
  }

  @override
  void initState() {
    super.initState();
    _renderPdf();
  }

  @override
  Widget build(BuildContext context) {
    if (files != null) {
      return GestureDetector(
        onScaleStart: (ScaleStartDetails details) {
          _previousScale = _scale;
        },
        onScaleUpdate: (ScaleUpdateDetails details) {
          setState(() => _scale = _previousScale * details.scale);
          if(_scale <= widget.minZoom)
            setState(() => _scale = widget.minZoom);
          if(_scale >= widget.maxZoom)
            setState(() => _scale = widget.maxZoom);
        },
        onScaleEnd: (ScaleEndDetails details) {
          _previousScale = null;
        },
        child: Transform(
          transform: Matrix4.diagonal3(vector.Vector3(_scale, _scale, _scale)),
          alignment: FractionalOffset.center,
          child: SizedBox(
            height: widget.width,
            child: PageView(
              children: files.map((f) => Image.file(f)).toList(),
            ),
          ),
        ),
      );
    }

    return Container();
  }
}