package com.conectavida.admin;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.List;
import java.util.Map;

public class SupabaseTablePanel extends JPanel {
    private final DefaultTableModel tableModel;
    private final JTable table;
    private final String[] columnKeys;
    private final DataLoader dataLoader;
    private final ActionEventHandler addAction;

    public SupabaseTablePanel(String title,
                              String tableName,
                              String[] columnLabels,
                              String[] columnKeys,
                              DataLoader dataLoader,
                              ActionEventHandler addAction) {
        this.columnKeys = columnKeys;
        this.dataLoader = dataLoader;
        this.addAction = addAction;

        setLayout(new BorderLayout(8, 8));
        setBorder(BorderFactory.createTitledBorder(title));

        tableModel = new DefaultTableModel(columnLabels, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        table = new JTable(tableModel);
        table.setAutoCreateRowSorter(true);
        table.setFillsViewportHeight(true);

        JButton refreshButton = new JButton("Atualizar");
        refreshButton.addActionListener(this::onRefresh);

        JPanel buttons = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttons.add(refreshButton);
        if (addAction != null) {
            JButton addButton = new JButton("Adicionar");
            addButton.addActionListener(addAction::handle);
            buttons.add(addButton);
        }

        add(buttons, BorderLayout.NORTH);
        add(new JScrollPane(table), BorderLayout.CENTER);
    }

    public void refresh() {
        onRefresh(null);
    }

    private void onRefresh(ActionEvent event) {
        SwingUtilities.invokeLater(() -> {
            tableModel.setRowCount(0);
            try {
                List<Map<String, Object>> rows = dataLoader.load();
                for (Map<String, Object> row : rows) {
                    Object[] data = new Object[columnKeys.length];
                    for (int i = 0; i < columnKeys.length; i++) {
                        data[i] = row.getOrDefault(columnKeys[i], "");
                    }
                    tableModel.addRow(data);
                }
            } catch (Exception e) {
                JOptionPane.showMessageDialog(this, "Erro ao carregar dados: " + e.getMessage(), "Erro", JOptionPane.ERROR_MESSAGE);
            }
        });
    }

    public static interface DataLoader {
        List<Map<String, Object>> load() throws Exception;
    }

    public static interface ActionEventHandler {
        void handle(ActionEvent event);
    }
}
