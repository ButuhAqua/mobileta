import '../repositories/approval_repository.dart';

class CompleteRawMaterialRequest {

  final ApprovalRepository repository;

  CompleteRawMaterialRequest(
    this.repository,
  );

  Future<void> call({
    required String token,
    required int requestId,
    required String supplier,
    required String batchNotes,
    String? location,
    required List<Map<String, dynamic>> items,
  }) {

    return repository
        .completeRawMaterialRequest(

      token: token,
      requestId: requestId,

      supplier: supplier,
      batchNotes: batchNotes,
      location: location,
      items: items,
    );
  }
}