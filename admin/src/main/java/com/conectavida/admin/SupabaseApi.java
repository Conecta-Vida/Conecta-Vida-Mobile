package com.conectavida.admin;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

public class SupabaseApi {
    private static final HttpClient CLIENT = HttpClient.newHttpClient();
    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static Map<String, List<Map<String, Object>>> loadExampleData() throws IOException {
        Path path = Path.of("example_data.json");
        return MAPPER.readValue(path.toFile(), new TypeReference<>() {
        });
    }

    public static List<Map<String, Object>> fetchRows(String supabaseUrl, String table, String apiKey, String serviceRoleKey)
            throws IOException, InterruptedException {
        String url = buildTableUrl(supabaseUrl, table) + "?select=*";
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .headers("apikey", apiKey, "Authorization", "Bearer " + getAuthKey(serviceRoleKey, apiKey), "Accept", "application/json")
                .build();

        HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 200 && response.statusCode() < 300) {
            return MAPPER.readValue(response.body(), new TypeReference<>() {
            });
        }
        throw new IOException("Erro ao buscar dados: " + response.statusCode() + " - " + response.body());
    }

    public static void insertRows(String supabaseUrl, String table, List<Map<String, Object>> rows, String apiKey, String serviceRoleKey)
            throws IOException, InterruptedException {
        String url = buildTableUrl(supabaseUrl, table);
        String body = MAPPER.writeValueAsString(rows);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .headers(
                        "apikey", apiKey,
                        "Authorization", "Bearer " + getAuthKey(serviceRoleKey, apiKey),
                        "Content-Type", "application/json",
                        "Prefer", "return=minimal"
                )
                .build();

        HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOException("Erro ao inserir dados: " + response.statusCode() + " - " + response.body());
        }
    }

    public static void testConnection(String supabaseUrl, String apiKey, String serviceRoleKey)
            throws IOException, InterruptedException {
        String url = buildTableUrl(supabaseUrl, "usuarios") + "?select=id&limit=1";
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .GET()
                .headers("apikey", apiKey, "Authorization", "Bearer " + getAuthKey(serviceRoleKey, apiKey), "Accept", "application/json")
                .build();

        HttpResponse<String> response = CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOException("Conexão falhou: " + response.statusCode() + " - " + response.body());
        }
    }

    private static String buildTableUrl(String supabaseUrl, String table) {
        return supabaseUrl.replaceAll("/+$", "") + "/rest/v1/" + table;
    }

    private static String getAuthKey(String serviceRoleKey, String apiKey) {
        if (serviceRoleKey != null && !serviceRoleKey.isBlank()) {
            return serviceRoleKey;
        }
        return apiKey;
    }
}
