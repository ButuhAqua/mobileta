import '../entities/pengajuan.dart';
import '../repositories/pengajuan_repository.dart';

class CreatePengajuan {
  final PengajuanRepository repository;

  CreatePengajuan(this.repository);

  Future<void> call(Pengajuan pengajuan, String token) {
    return repository.createPengajuan(pengajuan, token);
  }
}