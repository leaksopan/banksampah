// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void printCurrentPageImpl() {
  html.window.print();
}

void printHtmlImpl(String title, String htmlContent) {
  final printWindow = html.window.open('', '_blank');
  if (printWindow == null) return;

  if (printWindow is html.Window) {
    final doc = printWindow.document as html.HtmlDocument;
    doc.body?.innerHtml = htmlContent;
    doc.title = title;

    final style = html.StyleElement();
    style.text = '''
      body {
        font-family: 'Segoe UI', Arial, sans-serif;
        margin: 20px;
        color: #000;
        background-color: #fff;
        font-size: 13px;
        line-height: 1.4;
      }
      .header {
        text-align: center;
        margin-bottom: 20px;
      }
      .header h2 {
        margin: 0;
        font-size: 18px;
        font-weight: bold;
      }
      .header p {
        margin: 4px 0 0 0;
        font-size: 12px;
      }
      .divider {
        border-top: 1px solid #000;
        margin: 15px 0;
      }
      .divider-dashed {
        border-top: 1px dashed #000;
        margin: 15px 0;
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin: 10px 0;
      }
      th, td {
        padding: 6px 4px;
        text-align: left;
        vertical-align: top;
      }
      th {
        border-bottom: 1px solid #000;
        border-top: 1px solid #000;
        font-weight: bold;
      }
      .text-right {
        text-align: right;
      }
      .text-center {
        text-align: center;
      }
      .font-bold {
        font-weight: bold;
      }
      .total-row {
        border-top: 1px solid #000;
        border-bottom: 1px solid #000;
        font-weight: bold;
      }
      .signature-section {
        margin-top: 40px;
        display: flex;
        justify-content: space-between;
      }
      .signature-box {
        text-align: center;
        width: 45%;
      }
      .signature-space {
        height: 60px;
      }
      .signature-line {
        border-top: 1px solid #000;
        margin-top: 5px;
      }
      @media print {
        body {
          margin: 10mm;
        }
      }
    ''';
    doc.head?.append(style);

    Future.delayed(const Duration(milliseconds: 500), () {
      printWindow.print();
      Future.delayed(const Duration(milliseconds: 500), () {
        printWindow.close();
      });
    });
  }
}
