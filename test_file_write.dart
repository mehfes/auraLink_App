import 'dart:io';

void main() {
  final path1 = r'C:\Users\KAAN\Documents\iot_signals.txt';
  final path2 = r'iot_signals_test.txt';
  
  print('Testing absolute path: \$path1');
  try {
    File(path1).writeAsStringSync('[TEST 1] Absolute path test\n', mode: FileMode.append);
    print('SUCCESS Absolute');
  } catch (e) {
    print('FAILED Absolute: \$e');
  }

  print('\nTesting relative path: \$path2');
  try {
    File(path2).writeAsStringSync('[TEST 2] Relative path test\n', mode: FileMode.append);
    print('SUCCESS Relative');
  } catch (e) {
    print('FAILED Relative: \$e');
  }
}
