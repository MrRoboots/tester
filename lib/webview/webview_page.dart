import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dom_builder/dom_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    Key? key,
    required this.title,
    required this.url,
  }) : super(key: key);

  final String title;
  final String url;

  @override
  State createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;

  String htmlContent = '';

  // int _progressValue = 0;

  double webViewHeight = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (int progress) {
          if (!mounted) {
            return;
          }
          debugPrint('WebView is loading (progress : $progress%)');
          // setState(() {
          //   _progressValue = progress;
          // });
        }, onPageFinished: (url) {
          // 注入 js
          _controller.runJavaScript('''const resizeObserver = new ResizeObserver(entries =>
          Resize.postMessage(document.documentElement.scrollHeight.toString()) )
          resizeObserver.observe(document.body)''');
        }),
      )
      ..addJavaScriptChannel('Resize', onMessageReceived: (JavaScriptMessage msg) {
        double height = double.parse(msg.message);
        setState(() {
          webViewHeight = height;
        });
      })
      ..loadFlutterAsset(widget.url);
    // ..loadHtmlString(widget.url);
    // ..loadRequest(Uri.parse(widget.url));

    init();
  }

  init() async {
    htmlContent = await rootBundle.loadString(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bool canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          // 网页可以返回时，优先返回上一页
          await _controller.goBack();
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.title),
        // ),
        body: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: () async => readHtml(), child: const Text('读取html')),
            // TextButton(onPressed: () async => changeWebData(), child: const Text('修改web页面颜色')),
            // TextButton(onPressed: () async => await html2pdf(), child: const Text('webview html2pdf')),
            Expanded(
              // height: webViewHeight,
              child: Container(
                // margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: WebViewWidget(
                  controller: _controller,
                ),
              ),
            ),
            /*          if (_progressValue != 100)
              LinearProgressIndicator(
                value: _progressValue / 100,
                backgroundColor: Colors.transparent,
                minHeight: 2,
              )
            else
              Gaps.empty,*/
          ],
        ),
      ),
    );
  }

  Future<void> html2pdf() async {
    Directory tempDir = await getTemporaryDirectory();
    var targetPath = '${tempDir.path}/';
    var targetFileName = "example_pdf_file";
    await FlutterHtmlToPdf.convertFromHtmlContent(htmlContent, targetPath, targetFileName);
  }

  Future<void> changeWebData() async {
    // htmlContent = htmlContent.replaceFirst('我的名字', '里斯');
    // htmlContent = htmlContent.replaceFirst('前端工程师', 'Android工程师');
    // htmlContent = htmlContent.replaceFirst('个人简介', '哈哈哈哈哈哈');
    // htmlContent = htmlContent.replaceFirst('本科', '硕士');
    // htmlContent = htmlContent.replaceFirst('良好的代码风格', '哈哈哈哈哈哈哈哈');

    htmlContent = htmlContent.replaceFirst('#000000', '#ffffff');
    _controller.loadHtmlString(htmlContent);
  }

  readHtml() async {
    // var div = $divHTML('<div class="container"><span>Builder</span></div>')
    //     ?.insertAt(0, $span(id: 's1', content: 'The '))
    //     .insertAfter('#s1', $span(id: 's2', content: 'DOM ', style: 'font-weight: bold'));
    // print(div?.buildHTML(withIndent: true));
    //
    // div?.select('#s1')?.remove();
    // print(div?.buildHTML(withIndent: true));

    // var html = $html(htmlContent);
    // html[0].insertAt(0, $span(id: 's1', content: 'The '));

    htmlContent = await rootBundle.loadString(widget.url);

    ///去除空格
    var nbsp = '&nbsp;';
    htmlContent = htmlContent.replaceAll('\xa0', nbsp);

    // log('replaceAll:${htmlContent}');
    var rootHtml = $htmlRoot(htmlContent);

    // String? headerClass =  rootHtml?.select('body');
    // log('headerClass:$headerClass');

    // log('headerClass:${rootHtml.toString()}');
    // log('content:${rootHtml?.content}');
    // log('content5:${rootHtml!.content?[4].selectByTag(['header'])?.buildHTML(withIndent: true)}');

    // log('content:${rootHtml?.select('header')?.content}');
    // log('nodes:${rootHtml?.select('header')?.nodes}');

    rootHtml?.select('header')?.nodeByIndex(0)?.remove();
    log('rootHtml:${rootHtml?.selectByTag(['header'])?.buildHTML(withIndent: true)}');

    DOMNode? domNode = rootHtml?.select('header')?.insertAt(0, $tag('h1', id: 's1', content: 'The '));
    log('nodes:${domNode?.nodes}');

    // rootHtml?.styleText = '';

    rootHtml?.styleText = '';

    String rootHtmlStr = rootHtml?.buildHTML(withIndent: true) ?? '';
    // log('rootHtmlStr:$rootHtmlStr');

    _controller.loadHtmlString(rootHtmlStr);

    // var div = $div(classes: 'container', content: [
    //   $span(id: 's1', content: 'The '),
    //   $span(id: 's2', style: 'font-weight: bold', content: 'DOM '),
    //   $span(content: 'Builder'),
    //   $table(head: [
    //     'Name',
    //     'Age'
    //   ], body: [
    //     ['Joe', 21],
    //     ['Smith', 30]
    //   ])
    // ]);
    //
    // // Moves down Joe's row, placing it after Smith's row:
    // div.select('tbody')!.select('tr')!.moveDown();
    //
    // print('===============');
    // print(div.buildHTML(withIndent: true));
    // print('===============');
    //
    // String content =  div.buildHTML(withIndent: true);
    // _controller.loadHtmlString(content);
  }
}
