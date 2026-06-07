package com.hireready.user;

import com.hireready.auth.Role;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User{

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(name = "user_name")
    private String name;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    private String refreshToken;
    private LocalDateTime refreshTokenExpiry;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

}
