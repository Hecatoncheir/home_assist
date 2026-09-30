import 'dart:typed_data';

/// Потоковый шифр RC4. Шифрование и расшифровка — одна и та же операция.
class Rc4 {
  Rc4(List<int> key) {
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + _state[i] + key[i % key.length]) & 0xFF;
      _swap(i, j);
    }
  }

  final Uint8List _state = Uint8List.fromList(List.generate(256, (i) => i));
  int _i = 0;
  int _j = 0;

  Uint8List process(List<int> input) {
    final output = Uint8List(input.length);
    for (var n = 0; n < input.length; n++) {
      output[n] = input[n] ^ _nextKeyByte();
    }
    return output;
  }

  int _nextKeyByte() {
    _i = (_i + 1) & 0xFF;
    _j = (_j + _state[_i]) & 0xFF;
    _swap(_i, _j);
    return _state[(_state[_i] + _state[_j]) & 0xFF];
  }

  void _swap(int a, int b) {
    final tmp = _state[a];
    _state[a] = _state[b];
    _state[b] = tmp;
  }
}
