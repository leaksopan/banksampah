import 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart';

class AppPrintHelper {
  const AppPrintHelper._();

  static void printCurrentPage() {
    printCurrentPageImpl();
  }

  static void printHtml({required String title, required String htmlContent}) {
    printHtmlImpl(title, htmlContent);
  }

  static void exportCsv({required String filename, required String csvContent}) {
    exportCsvImpl(filename, csvContent);
  }
}
