package com.conectavida.admin;

import javax.swing.*;
import java.awt.*;

public class SupabaseConfigPanel extends JPanel {
    private final JTextField supabaseUrlField = new JTextField("https://YOUR_PROJECT_REF.supabase.co", 40);
    private final JTextField anonKeyField = new JTextField("YOUR_SUPABASE_ANON_KEY", 40);
    private final JTextField serviceRoleKeyField = new JTextField("YOUR_SUPABASE_SERVICE_ROLE_KEY", 40);

    public SupabaseConfigPanel() {
        setLayout(new GridBagLayout());
        setBorder(BorderFactory.createTitledBorder("Configuração Supabase"));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.anchor = GridBagConstraints.WEST;

        gbc.gridx = 0;
        gbc.gridy = 0;
        add(new JLabel("URL do Supabase:"), gbc);

        gbc.gridx = 1;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        add(supabaseUrlField, gbc);

        gbc.gridx = 0;
        gbc.gridy = 1;
        gbc.fill = GridBagConstraints.NONE;
        add(new JLabel("Chave Anon:"), gbc);

        gbc.gridx = 1;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        add(anonKeyField, gbc);

        gbc.gridx = 0;
        gbc.gridy = 2;
        gbc.fill = GridBagConstraints.NONE;
        add(new JLabel("Service Role Key:"), gbc);

        gbc.gridx = 1;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        add(serviceRoleKeyField, gbc);
    }

    public String getSupabaseUrl() {
        return supabaseUrlField.getText().trim();
    }

    public String getAnonKey() {
        return anonKeyField.getText().trim();
    }

    public String getServiceRoleKey() {
        return serviceRoleKeyField.getText().trim();
    }
}
