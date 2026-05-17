package com.conectavida.admin;

import javax.swing.*;
import java.awt.*;
import java.util.LinkedHashMap;
import java.util.Map;

public class SupabaseRecordDialog extends JDialog {
    private final Map<String, JTextField> fields = new LinkedHashMap<>();
    private boolean confirmed;

    public SupabaseRecordDialog(JFrame owner, String title, String[] labels, String[] keys) {
        super(owner, title, true);
        setLayout(new BorderLayout(12, 12));

        JPanel formPanel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.anchor = GridBagConstraints.WEST;
        gbc.fill = GridBagConstraints.HORIZONTAL;

        for (int i = 0; i < keys.length; i++) {
            gbc.gridx = 0;
            gbc.gridy = i;
            formPanel.add(new JLabel(labels[i] + ":"), gbc);

            gbc.gridx = 1;
            JTextField field = new JTextField(30);
            fields.put(keys[i], field);
            formPanel.add(field, gbc);
        }

        JButton confirmButton = new JButton("Salvar");
        confirmButton.addActionListener(e -> {
            confirmed = true;
            setVisible(false);
        });

        JButton cancelButton = new JButton("Cancelar");
        cancelButton.addActionListener(e -> setVisible(false));

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.add(cancelButton);
        buttonPanel.add(confirmButton);

        add(formPanel, BorderLayout.CENTER);
        add(buttonPanel, BorderLayout.SOUTH);

        pack();
        setLocationRelativeTo(owner);
    }

    public boolean isConfirmed() {
        return confirmed;
    }

    public Map<String, Object> getValues() {
        Map<String, Object> result = new LinkedHashMap<>();
        fields.forEach((key, field) -> result.put(key, field.getText().trim()));
        return result;
    }
}
