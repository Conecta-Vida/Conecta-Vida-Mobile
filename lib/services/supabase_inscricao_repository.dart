import '../models/dependente.dart';
import '../models/inscricao.dart';
import '../usecases/inscricao_campanha_service.dart';
import 'supabase_service.dart';

/// Implementação de [InscricaoRepository] sobre o Supabase. As regras de
/// acesso (RLS) do banco continuam valendo como segunda barreira.
class SupabaseInscricaoRepository implements InscricaoRepository {
  const SupabaseInscricaoRepository();

  @override
  Future<List<DependenteModel>> buscarDependentesAtivos(int usuarioId) =>
      SupabaseService.fetchDependentes(usuarioId, somenteAtivos: true);

  @override
  Future<List<Inscricao>> buscarInscricoes(int comunicacaoId) async {
    final linhas = await SupabaseService.fetchInscritosCampanha(comunicacaoId);
    return linhas.map(Inscricao.fromMap).toList();
  }

  @override
  Future<void> inscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) => SupabaseService.inscreverUsuarioEmCampanha(
    comunicacaoId: comunicacaoId,
    usuarioId: usuarioId,
    dependenteId: dependenteId,
  );

  @override
  Future<void> desinscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) => SupabaseService.desinscreverUsuarioDaCampanha(
    comunicacaoId: comunicacaoId,
    usuarioId: usuarioId,
    dependenteId: dependenteId,
  );
}
