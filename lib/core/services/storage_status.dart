import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageStatusProvider = NotifierProvider<StorageStatus, bool>(
  StorageStatus.new,
);

class StorageStatus extends Notifier<bool> {
  @override
  bool build() => true;
  void report(bool saved) => state = saved;
}
