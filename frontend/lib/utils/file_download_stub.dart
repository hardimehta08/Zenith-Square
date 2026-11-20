import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

const _pdfDownloadsChannel = MethodChannel(
  'com.example.frontend/pdf_downloads',
);

Future<bool> downloadWebFile({
  required String fileName,
  required String content,
  String mimeType = 'text/html',
}) async {
  throw UnsupportedError('HTML file downloads are only supported on web.');
}

Future<bool> downloadWebBinaryFile({
  required String fileName,
  required List<int> bytes,
  String mimeType = 'application/pdf',
}) async {
  if (mimeType != 'application/pdf') {
    throw UnsupportedError('Only PDF downloads are supported on this device.');
  }
  final fileBytes = Uint8List.fromList(bytes);
  if (Platform.isAndroid) {
    final savedToDownloads = await _pdfDownloadsChannel.invokeMethod<bool>(
      'savePdfToDownloads',
      {'fileName': fileName, 'bytes': fileBytes},
    );
    if (savedToDownloads != null) return savedToDownloads;
  }

  final name = fileName.toLowerCase().endsWith('.pdf')
      ? fileName.substring(0, fileName.length - 4)
      : fileName;
  final savedPath = await FileSaver.instance.saveAs(
    name: name,
    bytes: fileBytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
  return savedPath != null;
}

void printWebDocument(String htmlContent) {
  throw UnsupportedError('HTML printing is only supported on web.');
}

Future<void> openWebPdf(List<int> bytes) async {
  await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
}
