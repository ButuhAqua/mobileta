import '../entities/pengajuan.dart';

abstract class PengajuanRepository {
  Future<void> createPengajuan(Pengajuan pengajuan, String token);

  Future<List<Pengajuan>> getPengajuanList(String token);
}