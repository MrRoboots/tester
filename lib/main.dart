import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:ui' as ui;

import 'package:pdf_image_renderer/pdf_image_renderer.dart';
import 'package:tester/webview/webview_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey globalKey = GlobalKey();
  late final Directory tempDir;
  late String htmlContent;

  @override
  void initState() {
    init();

    super.initState();
  }

  init() async {
    tempDir = await getTemporaryDirectory();
    htmlContent = await rootBundle.loadString('assets/test.html');
  }

  @override
  Widget build(BuildContext context) {
    ///
    ///
    /// html2pdf
    /// 1.flutter_html_to_pdf 转pdf
    ///
    /// pdf转img
    /// 1.pdf_image_renderer
    /// 2.flutter_inappwebview截图方案
    ///
    ///
    ///
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // TextButton(
            //     onPressed: () async => await inappwebview(), child: const Text('flutter_inappwebview截图方案')),
            TextButton(onPressed: () async => await pdf2Img(), child: const Text('pdf转图片')),
            // TextButton(onPressed: () async => await html2pdf(), child: const Text('html2pdf')),

            /* Expanded(
                child: RepaintBoundary(
              key: globalKey,
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: Uri.parse("https://www.baidu.com")),
              ),
            ))*/

            const Expanded(
                child: WebViewPage(
              url: 'assets/test.html',
              // url: 'assets/test2.html',
              title: '',
            ))
          ],
        ),
      ),
    );
  }

  ///第一种截图方案
  Future<void> inappwebview() async {
    RenderRepaintBoundary boundary = globalKey.currentContext?.findRenderObject()! as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? bytes = byteData?.buffer.asUint8List();

    //转换成图片
    //获取路径
    File file = File('${tempDir.path}/testImg.png');
    await file.writeAsBytes(bytes!.toList());
  }

  Future<void> html2pdf() async {
    var targetPath = '${tempDir.path}/';
    var targetFileName = "example_pdf_file";
    await FlutterHtmlToPdf.convertFromHtmlContent(htmlContent, targetPath, targetFileName);
  }

  Future<void> pdf2Img() async {
    var targetPath = '${tempDir.path}/example_pdf_file.pdf';
    final pdf = PdfImageRendererPdf(path: targetPath);

    // open the pdf document
    await pdf.open();

    int pageCount = await pdf.getPageCount();
    log('pageCount:$pageCount');

    // open a page from the pdf document using the page index
    await pdf.openPage(pageIndex: 0);

    // get the render size after the page is loaded
    final size = await pdf.getPageSize(pageIndex: 0);

    // get the actual image of the page
    final img = await pdf.renderPage(
      pageIndex: 0,
      x: 0,
      y: 0,
      width: size.width,
      // you can pass a custom size here to crop the image
      height: size.height,
      // you can pass a custom size here to crop the image
      scale: 1,
      // increase the scale for better quality (e.g. for zooming)
      background: Colors.white,
    );

    // close the page again
    await pdf.closePage(pageIndex: 0);

    // close the PDF after rendering the page
    pdf.close();

    File file = File('${tempDir.path}/pdf2Img.png');
    await file.writeAsBytes(img!.toList());
  }
}
