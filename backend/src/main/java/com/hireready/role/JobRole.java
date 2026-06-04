package com.hireready.role;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "job_roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class JobRole {

    @Id
    private String id;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String category;

    @Column(name = "icon_name", nullable = false)
    private String iconName;

    @Column(name = "color_hex", nullable = false)
    private String colorHex;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;
}
