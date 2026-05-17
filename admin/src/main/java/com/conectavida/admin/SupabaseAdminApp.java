package com.conectavida.admin;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class SupabaseAdminApp extends JFrame {
    private final SupabaseConfigPanel configPanel = new SupabaseConfigPanel();
    private final SupabaseTablePanel newsPanel;
    private final SupabaseTablePanel usersPanel;
    private final SupabaseTablePanel sharedPanel;
    private final SupabaseTablePanel commitmentsPanel;
    private final JTextArea logArea = new JTextArea();

    public SupabaseAdminApp() {
        super("Conecta Vida Admin - Java");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1080, 760);
        setLocationRelativeTo(null);

        newsPanel = new SupabaseTablePanel(
                "Notícias",
                "noticias",
                new String[]{"ID", "Título", "Categoria", "Órgão", "Data", "Local"},
                new String[]{"id", "titulo", "categoria", "orgao", "data", "local"},
                this::loadNewsRows,
                this::onAddNews
        );

        usersPanel = new SupabaseTablePanel(
                "Usuários",
                "usuarios",
                new String[]{"ID", "Nome", "Email", "Idade", "Sexo", "Localização"},
                new String[]{"id", "nome", "email", "idade", "sexo", "localizacao"},
                this::loadUsersRows,
                null
        );

        sharedPanel = new SupabaseTablePanel(
                "Compartilhamentos",
                "noticias_compartilhadas",
                new String[]{"ID", "Título", "Categoria", "Compartilhado por", "Quando"},
                new String[]{"id", "titulo", "categoria", "shared_by", "shared_at"},
                this::loadSharedRows,
                null
        );

        commitmentsPanel = new SupabaseTablePanel(
                "Compromissos",
                "compromissos",
                new String[]{"ID", "Título", "Descrição", "Data", "Local"},
                new String[]{"id", "titulo", "descricao", "data", "local"},
                this::loadCommitmentRows,
                this::onAddCommitment
        );

        initUI();
    }

    private void initUI() {
        logArea.setEditable(false);
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));

        JButton testButton = new JButton("Testar conexão");
        testButton.addActionListener(this::onTestConnection);

        JButton syncButton = new JButton("Sincronizar dados de exemplo");
        syncButton.addActionListener(this::onSyncExamples);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 12, 8));
        buttonPanel.add(testButton);
        buttonPanel.add(syncButton);

        JTabbedPane tabbedPane = new JTabbedPane();
        tabbedPane.addTab("Notícias", newsPanel);
        tabbedPane.addTab("Usuários", usersPanel);
        tabbedPane.addTab("Compartilhamentos", sharedPanel);
        tabbedPane.addTab("Compromissos", commitmentsPanel);

        JPanel topPanel = new JPanel(new BorderLayout(12, 12));
        topPanel.add(configPanel, BorderLayout.CENTER);
        topPanel.add(buttonPanel, BorderLayout.SOUTH);

        JPanel mainPanel = new JPanel(new BorderLayout(12, 12));
        mainPanel.setBorder(BorderFactory.createEmptyBorder(12, 12, 12, 12));
        mainPanel.add(topPanel, BorderLayout.NORTH);
        mainPanel.add(tabbedPane, BorderLayout.CENTER);

        JScrollPane logScroll = new JScrollPane(logArea);
        logScroll.setBorder(BorderFactory.createTitledBorder("Log de execução"));
        logScroll.setPreferredSize(new Dimension(-1, 160));

        setLayout(new BorderLayout(12, 12));
        add(mainPanel, BorderLayout.CENTER);
        add(logScroll, BorderLayout.SOUTH);
    }

    private void onTestConnection(ActionEvent event) {
        runBackgroundTask(() -> {
            appendLog("Testando conexão com Supabase...");
            try {
                SupabaseApi.testConnection(configPanel.getSupabaseUrl(), configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                appendLog("Conexão estabelecida com sucesso.");
            } catch (IOException | InterruptedException e) {
                appendLog("Falha ao testar conexão: " + e.getMessage());
            }
        });
    }

    @SuppressWarnings("unused")
    private List<Map<String, Object>> loadNewsRows() throws IOException, InterruptedException {
        return SupabaseApi.fetchRows(configPanel.getSupabaseUrl(), "noticias", configPanel.getAnonKey(), configPanel.getServiceRoleKey());
    }

    @SuppressWarnings("unused")
    private List<Map<String, Object>> loadUsersRows() throws IOException, InterruptedException {
        return SupabaseApi.fetchRows(configPanel.getSupabaseUrl(), "usuarios", configPanel.getAnonKey(), configPanel.getServiceRoleKey());
    }

    @SuppressWarnings("unused")
    private List<Map<String, Object>> loadSharedRows() throws IOException, InterruptedException {
        return SupabaseApi.fetchRows(configPanel.getSupabaseUrl(), "noticias_compartilhadas", configPanel.getAnonKey(), configPanel.getServiceRoleKey());
    }

    @SuppressWarnings("unused")
    private List<Map<String, Object>> loadCommitmentRows() throws IOException, InterruptedException {
        return SupabaseApi.fetchRows(configPanel.getSupabaseUrl(), "compromissos", configPanel.getAnonKey(), configPanel.getServiceRoleKey());
    }

    @SuppressWarnings("unused")
    private void onAddNews(ActionEvent event) {
        String[] labels = {"Tag", "Título", "Subtítulo", "Descrição", "Categoria", "Data", "Local", "Órgão", "Telefone", "Site", "Imagem"};
        String[] keys = {"tag", "titulo", "subtitulo", "descricao", "categoria", "data", "local", "orgao", "orgaoTelefone", "orgaoSite", "imagem"};

        SupabaseRecordDialog dialog = new SupabaseRecordDialog(this, "Nova notícia", labels, keys);
        dialog.setVisible(true);
        if (dialog.isConfirmed()) {
            runBackgroundTask(() -> {
                try {
                    List<Map<String, Object>> row = List.of(dialog.getValues());
                    SupabaseApi.insertRows(configPanel.getSupabaseUrl(), "noticias", row, configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                    appendLog("Notícia adicionada com sucesso.");
                    newsPanel.refresh();
                } catch (IOException | InterruptedException e) {
                    appendLog("Erro ao adicionar notícia: " + e.getMessage());
                }
            });
        }
    }

    @SuppressWarnings("unused")
    private void onAddCommitment(ActionEvent event) {
        String[] labels = {"Título", "Descrição", "Data", "Local"};
        String[] keys = {"titulo", "descricao", "data", "local"};

        SupabaseRecordDialog dialog = new SupabaseRecordDialog(this, "Novo compromisso", labels, keys);
        dialog.setVisible(true);
        if (dialog.isConfirmed()) {
            runBackgroundTask(() -> {
                try {
                    List<Map<String, Object>> row = List.of(dialog.getValues());
                    SupabaseApi.insertRows(configPanel.getSupabaseUrl(), "compromissos", row, configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                    appendLog("Compromisso adicionado com sucesso.");
                    commitmentsPanel.refresh();
                } catch (IOException | InterruptedException e) {
                    appendLog("Erro ao adicionar compromisso: " + e.getMessage());
                }
            });
        }
    }

    private void onSyncExamples(ActionEvent event) {
        runBackgroundTask(() -> {
            appendLog("Sincronizando dados de exemplo para Supabase...");
            try {
                var payload = SupabaseApi.loadExampleData();
                @SuppressWarnings("unchecked")
                var noticias = (List<Map<String, Object>>) payload.get("noticias");
                @SuppressWarnings("unchecked")
                var usuarios = (List<Map<String, Object>>) payload.get("usuarios");
                @SuppressWarnings("unchecked")
                var compromissos = (List<Map<String, Object>>) payload.get("compromissos");

                SupabaseApi.insertRows(configPanel.getSupabaseUrl(), "noticias", noticias, configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                appendLog("Notícias de exemplo sincronizadas: " + noticias.size());
                SupabaseApi.insertRows(configPanel.getSupabaseUrl(), "usuarios", usuarios, configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                appendLog("Usuários de exemplo sincronizados: " + usuarios.size());
                if (compromissos != null) {
                    SupabaseApi.insertRows(configPanel.getSupabaseUrl(), "compromissos", compromissos, configPanel.getAnonKey(), configPanel.getServiceRoleKey());
                    appendLog("Compromissos de exemplo sincronizados: " + compromissos.size());
                }

                newsPanel.refresh();
                usersPanel.refresh();
                commitmentsPanel.refresh();
            } catch (IOException | InterruptedException e) {
                appendLog("Erro na sincronização de exemplo: " + e.getMessage());
            }
        });
    }

    private void appendLog(String message) {
        SwingUtilities.invokeLater(() -> {
            logArea.append(message + "\n");
            logArea.setCaretPosition(logArea.getDocument().getLength());
        });
    }

    private void runBackgroundTask(Runnable task) {
        new Thread(() -> {
            try {
                task.run();
            } catch (Exception e) {
                appendLog("Erro interno: " + e.getMessage());
            }
        }).start();
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            SupabaseAdminApp frame = new SupabaseAdminApp();
            frame.setVisible(true);
        });
    }
}
