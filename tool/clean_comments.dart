import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Thư mục lib không tồn tại!');
    return;
  }

  int totalFiles = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      final beforeLength = content.length;

      // Xóa tất cả các dòng comment doc ///
      content = content.replaceAll(RegExp(r'^[ \t]*///.*$\n', multiLine: true), '');

      // Thay thế các section header kiểu // ======== Title ======== thành // Title
      content = content.replaceAllMapped(
          RegExp(r'^[ \t]*// =+ (.*?) =+$\n', multiLine: true),
          (match) => '  // ${match.group(1)}\n');
          
      // Thay thế các section header kiểu // ── Title ── thành // Title
      content = content.replaceAllMapped(
          RegExp(r'^[ \t]*// ──+ (.*?) ──+.*$\n', multiLine: true),
          (match) => '  // ${match.group(1)}\n');

      // Xóa các dòng comment // thông thường ở đầu file (như // lib/...)
      content = content.replaceAll(RegExp(r'^//.*$\n', multiLine: true), '');
      
      // Xóa các comment // thường (nhưng giữ lại // Title nếu nó được coi là header)
      // Cách đơn giản: Xóa tất cả các dòng bắt đầu bằng // mà không theo sau là chữ hoa bắt đầu của một header (dễ xóa nhầm), 
      // thay vào đó, ta xóa những comment rườm rà.
      // Dựa theo yêu cầu "như api_config", ta có thể xóa hết các comment trong hàm hoặc comment mô tả
      // Ta sẽ xóa các comment dòng có chứa tiếng việt thường hoặc không phải header.
      // Vì không thể phân biệt hoàn toàn bằng regex, ta xóa tất cả các comment bắt đầu bằng `// ` nhưng không phải là comment ta vừa format.
      // Header ta format sẽ là `  // Title` hoặc `// Title`.
      // Ta có thể tạm thời xóa các comment // nếu cần, hoặc để nguyên nếu regex quá phức tạp.
      
      // Xóa block header đầu file
      if (content.startsWith('// lib/')) {
        content = content.replaceFirst(RegExp(r'^(//.*\n)+'), '');
      }

      // Xóa khoảng trắng thừa liên tiếp
      content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      if (content.length != beforeLength) {
        entity.writeAsStringSync(content);
        totalFiles++;
        print('Đã dọn dẹp file: ${entity.path}');
      }
    }
  }

  print('\n✅ Hoàn tất! Đã dọn dẹp comment trong $totalFiles file.');
}
