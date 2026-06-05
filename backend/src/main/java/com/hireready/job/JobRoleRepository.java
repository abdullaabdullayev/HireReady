package com.hireready.job;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobRoleRepository extends JpaRepository<JobRole,Long> {
    List<JobRole> findAllByOrderByDisplayOrderAsc();
}
