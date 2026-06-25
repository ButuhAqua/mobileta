import '../../domain/entities/pengajuan.dart';
import '../../domain/repositories/pengajuan_repository.dart';
import '../datasources/pengajuan_remote_datasource.dart';
import '../models/pengajuan_model.dart';

class PengajuanRepositoryImpl implements PengajuanRepository {
  final PengajuanRemoteDataSource dataSource;

  PengajuanRepositoryImpl(this.dataSource);

  @override
  Future<void> createPengajuan(Pengajuan pengajuan, String token) async {
    final model = PengajuanModel(
      id: pengajuan.id,
      title: pengajuan.title,
      requestType: pengajuan.requestType,
      priority: pengajuan.priority,
      requestDate: pengajuan.requestDate,
      notes: pengajuan.notes,
      items: pengajuan.items,
      purchaseLocation: pengajuan.purchaseLocation,
      status: pengajuan.status,
    );

    await dataSource.createPengajuan(model, token);
  }

  @override
  Future<List<Pengajuan>> getPengajuanList(String token) async {
    return await dataSource.getPengajuanList(token);
  }
}