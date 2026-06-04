package com.hireready.role;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class JobRoleService {

    private final JobRoleRepository repo;

    public List<JobRoleResponse> getAllRoles() {
        return repo.findAllByOrderByDisplayOrderAsc()
                .stream()
                .map(JobRoleResponse::from)
                .toList();
    }
}
