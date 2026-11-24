// Exercicio 8 (Trabalho 2 de Qualidade de Software) - entrada para o ComplexGraph.
//
// O ComplexGraph le apenas codigo Java, e o Conecta Vida e implementado em Dart.
// Este arquivo traduz, comando a comando, o metodo salvarInscricoes() de
// lib/usecases/inscricao_campanha_service.dart: mesmas decisoes, na mesma ordem,
// com o mesmo laco e o mesmo try/catch. Os tipos auxiliares no fim do arquivo
// existem so para o codigo compilar; a logica analisada e a do metodo abaixo.

import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class InscricaoCampanhaService {

    private final InscricaoRepository repositorio;
    private final Relogio relogio;

    public InscricaoCampanhaService(InscricaoRepository repositorio, Relogio relogio) {
        this.repositorio = repositorio;
        this.relogio = relogio;
    }

    // Passos 5 e 6 do caso de uso: compara quem estava inscrito com quem foi
    // marcado e inscreve/cancela cada participante alterado (RN01 a RN04 e RN07).
    public ResultadoInscricao salvarInscricoes(Campanha campanha, Integer usuarioId,
            List<Participante> participantes, Set<String> inscritosAtuais,
            Set<String> escolhidos) throws InscricaoException {
        Integer comunicacaoId = campanha.getId();
        if (comunicacaoId == null) {
            throw new InscricaoException(MotivoRecusa.CAMPANHA_SEM_ID);
        }
        if (!campanha.ehCampanha()) {
            throw new InscricaoException(MotivoRecusa.NAO_E_CAMPANHA);
        }
        if (usuarioId == null) {
            throw new InscricaoException(MotivoRecusa.USUARIO_NAO_IDENTIFICADO);
        }
        // RN07: as inscricoes novas precisam caber nas vagas restantes (E6).
        if (!campanha.comportaNovas(quantidadeDeNovas(escolhidos, inscritosAtuais))) {
            throw new InscricaoException(MotivoRecusa.VAGAS_INSUFICIENTES);
        }

        boolean encerrada = campanha.encerradaEm(relogio.agora());
        List<String> falhas = new ArrayList<String>();
        int alteracoes = 0;

        for (Participante participante : participantes) {
            boolean estavaInscrito = inscritosAtuais.contains(participante.getChave());
            boolean deveEstarInscrito = escolhidos.contains(participante.getChave());
            // RN04: sem mudanca para este participante, nada a fazer.
            if (estavaInscrito == deveEstarInscrito) {
                continue;
            }
            if (deveEstarInscrito) {
                // RN02: campanha encerrada nao aceita inscricao nova.
                if (encerrada) {
                    falhas.add(participante.getNome() + ": campanha encerrada");
                    continue;
                }
                // RN03: so titular ou dependente com vinculo ativo.
                if (!participante.isVinculoAtivo()) {
                    falhas.add(participante.getNome() + ": vinculo nao esta ativo");
                    continue;
                }
            }
            try {
                if (deveEstarInscrito) {
                    repositorio.inscrever(comunicacaoId, usuarioId, participante.getDependenteId());
                } else {
                    repositorio.desinscrever(comunicacaoId, usuarioId, participante.getDependenteId());
                }
                alteracoes++;
            } catch (Exception erro) {
                falhas.add(participante.getNome() + ": " + erro.getMessage());
            }
        }

        return new ResultadoInscricao(alteracoes, escolhidos.size(), falhas);
    }

    // Equivale a escolhidos.difference(inscritosAtuais).length no Dart (sem decisoes).
    private static int quantidadeDeNovas(Set<String> escolhidos, Set<String> inscritosAtuais) {
        Set<String> novas = new HashSet<String>(escolhidos);
        novas.removeAll(inscritosAtuais);
        return novas.size();
    }
}

// ---------------------------------------------------------------- tipos auxiliares

interface InscricaoRepository {
    void inscrever(Integer comunicacaoId, Integer usuarioId, Integer dependenteId) throws Exception;

    void desinscrever(Integer comunicacaoId, Integer usuarioId, Integer dependenteId) throws Exception;
}

interface Relogio {
    Date agora();
}

interface Campanha {
    Integer getId();

    boolean ehCampanha();

    boolean encerradaEm(Date hoje);

    boolean comportaNovas(int quantidade);
}

interface Participante {
    String getChave();

    String getNome();

    boolean isVinculoAtivo();

    Integer getDependenteId();
}

enum MotivoRecusa {
    CAMPANHA_SEM_ID, NAO_E_CAMPANHA, USUARIO_NAO_IDENTIFICADO, CAMPANHA_LOTADA, VAGAS_INSUFICIENTES
}

class InscricaoException extends Exception {
    private final MotivoRecusa motivo;

    InscricaoException(MotivoRecusa motivo) {
        super(motivo.name());
        this.motivo = motivo;
    }

    MotivoRecusa getMotivo() {
        return motivo;
    }
}

class ResultadoInscricao {
    final int alteracoes;
    final int selecionados;
    final List<String> falhas;

    ResultadoInscricao(int alteracoes, int selecionados, List<String> falhas) {
        this.alteracoes = alteracoes;
        this.selecionados = selecionados;
        this.falhas = falhas;
    }
}
