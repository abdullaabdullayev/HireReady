package com.hireready.role;

public record JobRoleResponse(
        String id,
        String title,
        String category,
        String iconName,
        String colorHex
) {

    public static JobRoleResponse from(JobRole r) {
        return new JobRoleResponse(
                r.getId(), r.getTitle(), r.getCategory(),
                r.getIconName(), r.getColorHex()
        );
    }
}
