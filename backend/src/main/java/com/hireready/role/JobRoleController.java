package com.hireready.role;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
public class JobRoleController {

    private final JobRoleService service;

    @GetMapping
    List<JobRoleResponse> getJobRoles() {
        return service.getAllRoles();
    }
}
