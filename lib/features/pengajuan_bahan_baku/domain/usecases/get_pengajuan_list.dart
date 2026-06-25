import '../entities/pengajuan.dart';
import '../repositories/pengajuan_repository.dart';

class GetPengajuanList {
  final PengajuanRepository repository;

  GetPengajuanList(this.repository);

  Future<List<Pengajuan>> call(String token) {
    return repository.getPengajuanList(token);
  }
}