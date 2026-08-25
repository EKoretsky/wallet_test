String formatAddressForCell(String address, double textScaleFactor) {
  final addressParts = address.splitHexPrefix();
  final prefix = addressParts.prefix;

  if (addressParts.body.length <= 12) {
    return address;
  }

  final leadingCharacterCount = textScaleFactor < 1.6 ? 6 : 4;
  final leading = addressParts.body.substring(0, leadingCharacterCount);
  final trailing = addressParts.body.substring(addressParts.body.length - 4);
  const placeholder = '…';

  return '$prefix$leading$placeholder$trailing';
}

extension on String {
  ({String prefix, String body}) splitHexPrefix() {
    const prefix = '0x';
    final hasPrefix = startsWith(prefix);

    return (
      prefix: hasPrefix ? substring(0, prefix.length) : '',
      body: hasPrefix ? substring(prefix.length) : this,
    );
  }
}
