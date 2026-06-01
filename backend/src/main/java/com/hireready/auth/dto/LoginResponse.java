package com.hireready.auth.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class LoginResponse {

   private UUID uuid;
   private String email;
   private String name;
}
