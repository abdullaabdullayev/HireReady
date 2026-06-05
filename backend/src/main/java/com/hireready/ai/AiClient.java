package com.hireready.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;

@Component
public class AiClient {

    @Value("${ai.gemini.api-key}")
    private String apiKey;

    @Value("${ai.gemini.base-url}")
    private String baseUrl;

    @Value("${ai.gemini.model}")
    private String model;

    private RestClient client;

    public String chat(String systemPrompt, String userPrompt){

        if(client == null){
            client = RestClient.builder()
                    .baseUrl(baseUrl)
                    .build();
        }



    }
}
