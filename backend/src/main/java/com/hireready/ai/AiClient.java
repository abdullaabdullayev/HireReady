package com.hireready.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Component
public class AiClient {

    @Value("${ai.groq.api-key}")
    private String apiKey;

    @Value("${ai.groq.base-url}")
    private String baseUrl;

    @Value("${ai.groq.model}")
    private String model;

    private RestClient client;

    public String chat(String systemPrompt, String userPrompt) {

        if (client == null) {
            client = RestClient.builder()
                    .baseUrl(baseUrl)
                    .build();
        }

        Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(
                        Map.of("role", "system", "content", systemPrompt),
                        Map.of("role", "user",   "content", userPrompt)
                ),
                "temperature", 0.3,
                "response_format", Map.of("type", "json_object")
        );

        Map response = client.post()
                .uri("/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .header("Content-Type", "application/json")
                .body(body)
                .retrieve()
                .body(Map.class);

        var choices = (List<Map>) response.get("choices");
        var message = (Map) choices.get(0).get("message");
        return (String) message.get("content");
    }
}