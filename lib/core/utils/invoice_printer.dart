import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../models/cart_item.dart';
import '../../l10n/app_localizations.dart';
import 'currency_formatter.dart';
import 'printer_settings_helper.dart';

class InvoicePrinter {
  static pw.Font? _arabicFont;
  static pw.Font? _arabicBoldFont;
  
  static Future<pw.Font> _getArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;
    
    try {
      // Load Arabic font from assets
      final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
      _arabicFont = pw.Font.ttf(fontData);
      debugPrint('Arabic font loaded successfully');
      return _arabicFont!;
    } catch (e) {
      // If font loading fails, try alternative paths
      debugPrint('Warning: Could not load Arabic font from assets: $e');
      try {
        // Try with assets prefix
        final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
        _arabicFont = pw.Font.ttf(fontData);
        debugPrint('Arabic font loaded from assets/fonts/');
        return _arabicFont!;
      } catch (e2) {
        debugPrint('Warning: Could not load Arabic font from assets/fonts: $e2');
        debugPrint('Arabic text may not display correctly. Please ensure fonts/NotoSansArabic-Regular.ttf exists.');
        // Use a built-in font as fallback - won't support Arabic properly
        _arabicFont = pw.Font.helvetica();
        return _arabicFont!;
      }
    }
  }
  
  static Future<pw.Font> _getArabicBoldFont() async {
    if (_arabicBoldFont != null) return _arabicBoldFont!;
    
    try {
      // Try to load bold variant if it exists
      final fontData = await rootBundle.load('fonts/NotoSansArabic-Bold.ttf');
      _arabicBoldFont = pw.Font.ttf(fontData);
      return _arabicBoldFont!;
    } catch (e) {
      // Fall back to regular font
      _arabicBoldFont = await _getArabicFont();
      return _arabicBoldFont!;
    }
  }
  
  /// Get page format from saved printer settings
  static Future<PdfPageFormat> _getPageFormat() async {
    final settings = await PrinterSettingsHelper.loadSettings();
    final width = settings.width * PdfPageFormat.mm;
    final height = settings.height == double.infinity 
        ? double.infinity 
        : settings.height * PdfPageFormat.mm;
    
    return PdfPageFormat(
      width,
      height,
      marginAll: 4 * PdfPageFormat.mm,
    );
  }

  /// Get full page format for reports (minimal margins)
  static Future<PdfPageFormat> _getFullPageFormat() async {
    final settings = await PrinterSettingsHelper.loadSettings();
    final width = settings.width * PdfPageFormat.mm;
    final height = settings.height == double.infinity 
        ? double.infinity 
        : settings.height * PdfPageFormat.mm;
    
    return PdfPageFormat(
      width,
      height,
      marginAll: 2 * PdfPageFormat.mm, // Minimal margins for full page
    );
  }
  
  static Future<void> printCustomerInvoice({
    required List<CartItem> items,
    required double total,
    double discountPercentage = 0.0,
    double discountAmount = 0.0,
    double serviceCharge = 0.0,
    double deliveryTax = 0.0,
    double hospitalityTax = 0.0,
    String? tableNumber,
    String? orderNumber,
    String? invoiceNumber,
    AppLocalizations? l10n,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final font = await _getArabicFont();
    
    // Business info (you can make this configurable)
    const businessName = 'Queen Café';
    const businessAddress = 'القناطر الخيرية - كورنيش النيل';
    
    // Calculate values
    // Total passed is already the final total after discount, service charge, and delivery tax
    // Hospitality is included in discountAmount, not as a separate tax
    // We need to calculate subtotal from items
    final itemsSubtotal = items.fold(0.0, (sum, item) => sum + item.total);
    final subtotal = itemsSubtotal;
    final service = serviceCharge; // Use passed service charge
    final deliveryService = deliveryTax; // Use passed delivery tax
    // hospitalityTax is now part of discountAmount, not shown separately
    final discount = discountAmount; // Use passed discount amount (includes hospitality discount if applicable)
    final netTotal = total; // Use the final total passed (already includes discount, service charge, and delivery tax)
    
    // Get page format from settings
    final pageFormat = await _getPageFormat();
    
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Business Name
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
                
                // Invoice Type
                pw.Text(
                  l10n?.salesInvoice ?? 'فاتورة مبيعات',
                  style: pw.TextStyle(fontSize: 12, font: font),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                ),
                pw.SizedBox(height: 8),
                
                // Table Number
                if (tableNumber != null)
                  pw.Text(
                    '${l10n?.tableNumber ?? "رقم الطاولة"}: $tableNumber',
                    style: pw.TextStyle(fontSize: 10, font: font),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                if (tableNumber != null) pw.SizedBox(height: 4),
                
                // Order Number
                if (orderNumber != null)
                  pw.Text(
                    '${l10n?.orderNumber ?? "رقم الطلب"}: $orderNumber',
                    style: pw.TextStyle(fontSize: 10, font: font),
                    maxLines: 1,
                  ),
                if (orderNumber != null) pw.SizedBox(height: 4),
                
                // Invoice Number
                if (invoiceNumber != null)
                  pw.Text(
                    '${l10n?.invoiceNumber ?? "فاتورة رقم"}: $invoiceNumber',
                    style: pw.TextStyle(fontSize: 10, font: font),
                    maxLines: 1,
                  ),
                pw.SizedBox(height: 8),
                
                // Date and Time
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Flexible(
                      child: pw.Text(
                        '${now.day}/${now.month}/${now.year}',
                        style: pw.TextStyle(fontSize: 9, font: font),
                        maxLines: 1,
                      ),
                    ),
                    pw.Flexible(
                      child: pw.Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "م" : "ص"}',
                        style: pw.TextStyle(fontSize: 9, font: font),
                        maxLines: 1,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                
                pw.Divider(),
                pw.SizedBox(height: 4),
                
                // Items Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Flexible(
                      flex: 2,
                      child: pw.Text(
                        l10n?.value ?? 'القيمة',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                        maxLines: 1,
                        textAlign: pw.TextAlign.left,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Flexible(
                      flex: 1,
                      child: pw.Text(
                        l10n?.quantity ?? 'الكميه',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                        maxLines: 1,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Flexible(
                      flex: 3,
                      child: pw.Text(
                        '${l10n?.item ?? "الصنف"} / ${l10n?.quantity ?? "الكميه"}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                        textAlign: pw.TextAlign.right,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),
                
                // Items List
                for (var item in items)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Flexible(
                          flex: 2,
                          child: pw.Text(
                            CurrencyFormatter.format(item.total),
                            style: pw.TextStyle(fontSize: 9, font: font),
                            maxLines: 1,
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Flexible(
                          flex: 1,
                          child: pw.Text(
                            CurrencyFormatter.formatInt(item.quantity),
                            style: pw.TextStyle(fontSize: 9, font: font),
                            maxLines: 1,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Flexible(
                          flex: 3,
                          child: pw.Text(
                            item.name,
                            style: pw.TextStyle(fontSize: 9, font: font),
                            textAlign: pw.TextAlign.right,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                pw.SizedBox(height: 8),
                pw.Divider(),
                pw.SizedBox(height: 4),
                
                // Totals
                _buildTotalRow(
                  l10n?.totalInvoice ?? 'اجمالي الفاتورة',
                  CurrencyFormatter.format(subtotal),
                ),
                if (discount > 0)
                  _buildTotalRow(
                    '${l10n?.totalDiscount ?? 'اجمالي الخصم'} (${CurrencyFormatter.formatDouble(discountPercentage, 1)}%)',
                    CurrencyFormatter.format(discount),
                  ),
                        if (service > 0) // Only show service charge if > 0
                          _buildTotalRow(
                            l10n?.service ?? 'خدمة',
                            CurrencyFormatter.format(service),
                          ),
                        if (deliveryService > 0) // Only show delivery tax if > 0
                          _buildTotalRow(
                            l10n?.deliveryService ?? 'خدمة توصيل',
                            CurrencyFormatter.format(deliveryService),
                          ),
                        // Note: Hospitality discount is included in the discount amount above, not shown separately
                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),
                _buildTotalRow(
                  l10n?.netInvoice ?? 'صافي الفاتورة',
                  CurrencyFormatter.format(netTotal),
                  isBold: true,
                ),
                pw.SizedBox(height: 12),
                
                // Footer
                pw.Text(
                  businessAddress,
                  style: pw.TextStyle(fontSize: 8, font: font),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  l10n?.welcome ?? 'اهلا بكم',
                  style: pw.TextStyle(fontSize: 8, font: font),
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
    
    final pdfBytes = await pdf.save();
    
    // Load printer settings
    final settings = await PrinterSettingsHelper.loadSettings();
    
    // Get available printers
    final printers = await Printing.listPrinters();
    if (printers.isEmpty) {
      debugPrint('No printers available');
      throw Exception('No printers available. Please connect a printer.');
    }
    
    // Try to find printer matching saved name, or use default printer
    Printer? printer;
    if (settings.printerName.isNotEmpty) {
      try {
        printer = printers.firstWhere(
          (p) => p.name == settings.printerName,
        );
        debugPrint('Using saved printer: ${printer.name}');
      } catch (e) {
        // If saved printer not found, try to find default printer or use first available
        printer = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        debugPrint('Saved printer "${settings.printerName}" not found, using: ${printer.name}');
      }
    } else {
      // No saved printer, use default printer or first available
      printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );
      debugPrint('Using printer: ${printer.name}');
    }
    
    // Print directly without dialog using saved settings
    debugPrint('Attempting to print directly to printer: ${printer.name}');
    debugPrint('PDF size: ${pdfBytes.length} bytes');
    
    try {
      // Print directly using the printer
      debugPrint('Calling Printing.directPrintPdf...');
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async {
          debugPrint('onLayout called with format: ${format.width}x${format.height}');
          // Return the PDF bytes - the format is already set in the PDF
          return pdfBytes;
        },
      );
      debugPrint('Print job sent successfully to printer: ${printer.name}');
    } catch (e, stackTrace) {
      debugPrint('Direct print failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // On Windows, directPrintPdf might not work reliably
      // Try using layoutPdf as fallback (this will show a dialog)
      try {
        debugPrint('Trying alternative print method with layoutPdf...');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            // Get page format from settings
            await _getPageFormat();
            return pdfBytes;
          },
        );
        // Note: layoutPdf opens a dialog, but it's a fallback
        debugPrint('Print dialog opened as fallback');
      } catch (e2) {
        debugPrint('Alternative print method also failed: $e2');
        // If all methods fail, throw the original error
        throw Exception('Failed to print: $e');
      }
    }
  }
  
  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: _arabicFont ?? pw.Font.courier(),
              ),
              maxLines: 1,
              textAlign: pw.TextAlign.left,
            ),
          ),
          pw.Flexible(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: _arabicFont ?? pw.Font.courier(),
              ),
              maxLines: 1,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  static Future<void> printKitchenInvoice({
    required List<CartItem> items,
    String? tableNumber,
    String? orderNumber,
    AppLocalizations? l10n,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final font = await _getArabicFont();
    
    // Get page format from settings
    final pageFormat = await _getPageFormat();
    
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Date and Time
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Flexible(
                      child: pw.Text(
                        '${now.day}/${now.month}/${now.year}',
                        style: pw.TextStyle(fontSize: 10, font: font),
                        maxLines: 1,
                      ),
                    ),
                    pw.Flexible(
                      child: pw.Text(
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "م" : "ص"}',
                        style: pw.TextStyle(fontSize: 10, font: font),
                        maxLines: 1,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                
                // Table Number
                if (tableNumber != null)
                  pw.Text(
                    tableNumber,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      font: font,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                pw.SizedBox(height: 8),
                
                // Order Number
                if (orderNumber != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Flexible(
                        child: pw.Text(
                          '${l10n?.orderNumber ?? "رقم الطلب"}: ',
                          style: pw.TextStyle(fontSize: 10, font: font),
                          maxLines: 1,
                        ),
                      ),
                      pw.Flexible(
                        child: pw.Text(
                          orderNumber,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 8),
                
                pw.Divider(),
                pw.SizedBox(height: 8),
                
                // Items Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Flexible(
                      flex: 1,
                      child: pw.Text(
                        l10n?.quantity ?? 'الكميه',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                        maxLines: 1,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Flexible(
                      flex: 3,
                      child: pw.Text(
                        l10n?.item ?? 'اسم الصنف',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                        textAlign: pw.TextAlign.right,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),
                
                // Items List
                for (var item in items)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Flexible(
                          flex: 1,
                          child: pw.Text(
                            CurrencyFormatter.formatInt(item.quantity),
                            style: pw.TextStyle(fontSize: 11, font: font),
                            maxLines: 1,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Flexible(
                          flex: 3,
                          child: pw.Text(
                            item.name,
                            style: pw.TextStyle(fontSize: 11, font: font),
                            textAlign: pw.TextAlign.right,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    
    final pdfBytes = await pdf.save();
    
    // Load printer settings
    final settings = await PrinterSettingsHelper.loadSettings();
    debugPrint('Kitchen invoice - Loaded printer settings: ${settings.printerName}, width: ${settings.width}, height: ${settings.height}');
    
    // Get available printers
    final printers = await Printing.listPrinters();
    debugPrint('Kitchen invoice - Found ${printers.length} printers');
    if (printers.isEmpty) {
      debugPrint('No printers available');
      throw Exception('No printers available. Please connect a printer.');
    }
    
    // Try to find printer matching saved name, or use default printer
    Printer? printer;
    if (settings.printerName.isNotEmpty) {
      try {
        printer = printers.firstWhere(
          (p) => p.name == settings.printerName,
        );
        debugPrint('Kitchen invoice - Using saved printer: ${printer.name}');
      } catch (e) {
        // If saved printer not found, try to find default printer or use first available
        printer = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        debugPrint('Kitchen invoice - Saved printer "${settings.printerName}" not found, using: ${printer.name}');
      }
    } else {
      // No saved printer, use default printer or first available
      printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );
      debugPrint('Kitchen invoice - No saved printer, using: ${printer.name}');
    }
    
    debugPrint('Kitchen invoice - Selected printer: ${printer.name}, isDefault: ${printer.isDefault}');
    
    // Print directly without dialog using saved settings
    debugPrint('Kitchen invoice - Attempting to print directly to printer: ${printer.name}');
    debugPrint('Kitchen invoice - PDF size: ${pdfBytes.length} bytes');
    
    try {
      // Print directly using the printer
      debugPrint('Kitchen invoice - Calling Printing.directPrintPdf...');
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async {
          debugPrint('Kitchen invoice - onLayout called with format: ${format.width}x${format.height}');
          // Return the PDF bytes - the format is already set in the PDF
          return pdfBytes;
        },
      );
      debugPrint('Kitchen invoice - Print job sent successfully to printer: ${printer.name}');
    } catch (e, stackTrace) {
      debugPrint('Kitchen invoice - Direct print failed: $e');
      debugPrint('Kitchen invoice - Stack trace: $stackTrace');
      
      // On Windows, directPrintPdf might not work reliably
      // Try using layoutPdf as fallback (this will show a dialog)
      try {
        debugPrint('Kitchen invoice - Trying alternative print method with layoutPdf...');
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            // Get page format from settings
            await _getPageFormat();
            return pdfBytes;
          },
        );
        // Note: layoutPdf opens a dialog, but it's a fallback
        debugPrint('Kitchen invoice - Print dialog opened as fallback');
      } catch (e2) {
        debugPrint('Kitchen invoice - Alternative print method also failed: $e2');
        // If all methods fail, throw the original error
        throw Exception('Failed to print: $e');
      }
    }
  }

  /// Print shift close report
  static Future<void> printShiftCloseReport({
    required String title,
    required DateTime reportDate,
    String? floorName,
    required double totalSales,
    required double discount,
    required double netSales,
    required double dineInService,
    required double deliveryService,
    required double creditSales,
    required double visa,
    required double costOfSales,
    required double cashSales,
    required double otherRevenues,
    required double totalReceipts,
    required double expensesAndPurchases,
    required double suppliesToSubTreasury,
    required double totalPayments,
    required double netMovementForDay,
    required double previousBalance,
    required double netCash,
    required Map<String, Map<String, dynamic>> itemizedSales,
    required int totalCount,
    AppLocalizations? l10n,
  }) async {
    final pdf = pw.Document();
    final font = await _getArabicFont();
    
    // Business info
    const businessName = 'Queen Café';
    
    // Get full page format for reports
    final pageFormat = await _getFullPageFormat();
    
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.max,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          font: font,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          font: font,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${_formatDate(reportDate)} ${_formatTime(reportDate)}',
                        style: pw.TextStyle(fontSize: 10, font: font),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (floorName != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          floorName,
                          style: pw.TextStyle(fontSize: 10, font: font),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 8),
                
                // Sales Section
                pw.Text(
                  l10n?.totalSales ?? 'المبيعات',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.SizedBox(height: 4),
              _buildReportRow(l10n?.totalSales ?? 'اجمالي المبيعات', _formatCurrency(totalSales), font),
              _buildReportRow(l10n?.discount ?? 'خصم', _formatCurrency(discount), font),
              _buildReportRow(l10n?.netSales ?? 'صافي المبيعات', _formatCurrency(netSales), font, isBold: true),
              _buildReportRow(l10n?.dineInService ?? 'خدمه صاله', _formatCurrency(dineInService), font),
              _buildReportRow(l10n?.deliveryService ?? 'خدمه توصیل', _formatCurrency(deliveryService), font),
              _buildReportRow(l10n?.creditSales ?? 'مبيعات وایرادات اجل', _formatCurrency(creditSales), font),
              _buildReportRow(l10n?.visa ?? 'فيزا', _formatCurrency(visa), font),
              _buildReportRow(l10n?.costOfSales ?? 'تكلفه المبيعات', _formatCurrency(costOfSales), font),
              pw.SizedBox(height: 8),
              
              // Receipts Section
              pw.Text(
                l10n?.totalReceipts ?? 'المقبوضات',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildReportRow(l10n?.cashSales ?? 'مبيعات نقدی', _formatCurrency(cashSales), font),
              _buildReportRow(l10n?.otherRevenues ?? 'ایرادات اخرى', _formatCurrency(otherRevenues), font),
              _buildReportRow(l10n?.totalReceipts ?? 'اجمالي المقبوضات', _formatCurrency(totalReceipts), font, isBold: true),
              pw.SizedBox(height: 8),
              
              // Payments Section
              pw.Text(
                l10n?.totalPayments ?? 'المدفوعات',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildReportRow(l10n?.expensesAndPurchases ?? 'مصروفات ومشتريات', _formatCurrency(expensesAndPurchases), font),
              _buildReportRow(l10n?.suppliesToSubTreasury ?? 'توريدات للخزينة الفرعيه', _formatCurrency(suppliesToSubTreasury), font),
              _buildReportRow(l10n?.totalPayments ?? 'اجمالي المدفوعات', _formatCurrency(totalPayments), font, isBold: true),
              pw.SizedBox(height: 8),
              
              // Summary Section
              _buildReportRow(l10n?.netMovementForDay ?? 'صافي حركة اليوم', _formatCurrency(netMovementForDay), font),
              _buildReportRow(l10n?.previousBalance ?? 'الرصيد السابق', _formatCurrency(previousBalance), font),
              _buildReportRow(l10n?.netCash ?? 'صافي النقدية', _formatCurrency(netCash), font, isBold: true),
              pw.SizedBox(height: 8),
              
              // Itemized Sales
              pw.Text(
                l10n?.itemizedSales ?? 'الأصناف المباعة',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              // Table header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      l10n?.item ?? 'الصنف',
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: font,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      l10n?.quantity ?? 'الكمية',
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: font,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      l10n?.value ?? 'القيمة',
                      style: pw.TextStyle(
                        fontSize: 10,
                        font: font,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              // Table rows
              ...itemizedSales.entries.map((entry) {
                final itemData = entry.value;
                final quantity = itemData['quantity'] as int;
                final total = itemData['total'] as double;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          entry.key,
                          style: pw.TextStyle(fontSize: 9, font: font),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          quantity.toString(),
                          style: pw.TextStyle(fontSize: 9, font: font),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          _formatCurrency(total),
                          style: pw.TextStyle(fontSize: 9, font: font),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 8),
              pw.Divider(),
              
              // Total Count
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    l10n?.totalCount ?? 'اجمالي العدد',
                    style: pw.TextStyle(
                      fontSize: 10,
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    totalCount.toString(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            ),
          );
        },
      ),
    );
    
    final pdfBytes = await pdf.save();
    
    // Load printer settings
    final settings = await PrinterSettingsHelper.loadSettings();
    
    // Get available printers
    final printers = await Printing.listPrinters();
    if (printers.isEmpty) {
      debugPrint('No printers available');
      throw Exception('No printers available. Please connect a printer.');
    }
    
    // Try to find printer matching saved name, or use default printer
    Printer? printer;
    if (settings.printerName.isNotEmpty) {
      try {
        printer = printers.firstWhere(
          (p) => p.name == settings.printerName,
        );
        debugPrint('Using saved printer: ${printer.name}');
      } catch (e) {
        printer = printers.firstWhere(
          (p) => p.isDefault,
          orElse: () => printers.first,
        );
        debugPrint('Saved printer "${settings.printerName}" not found, using: ${printer.name}');
      }
    } else {
      printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );
      debugPrint('Using printer: ${printer.name}');
    }
    
    // Print directly
    try {
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
      debugPrint('Report printed successfully to printer: ${printer.name}');
    } catch (e, stackTrace) {
      debugPrint('Direct print failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback to dialog
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
        debugPrint('Print dialog opened as fallback');
      } catch (e2) {
        debugPrint('Alternative print method also failed: $e2');
        throw Exception('Failed to print: $e');
      }
    }
  }

  static pw.Widget _buildReportRow(String label, String value, pw.Font font, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // In RTL context, value should be on the left, label on the right
          // So we reverse the order to match RTL layout
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              font: font,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.left,
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              font: font,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final hour12 = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  static String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }
}

