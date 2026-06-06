package com.hireready.document;

import com.hireready.common.enums.DocumentType;
import com.hireready.document.service.DocumentService;
import com.hireready.user.CustomUserDetails;
import com.hireready.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
public class DocumentController {

    private final DocumentService service;

    @PostMapping
    public DocumentResponse upload(
            @AuthenticationPrincipal CustomUserDetails principal,
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") DocumentType type){
        User user = service.currentUser(principal);
        return DocumentResponse.from(service.upload(user, file, type));

    }

    @GetMapping
    public List<DocumentResponse> getDocuments(@AuthenticationPrincipal CustomUserDetails principal){
        User user = service.currentUser(principal);
        return service.getUserDocuments(user).stream()
                .map(DocumentResponse::from)
                .toList();
    }

    @DeleteMapping("/{id}")
    public void delete(@AuthenticationPrincipal CustomUserDetails principal,
                                   @PathVariable UUID id){
        service.deleteUserDocuments(id, service.currentUser(principal));
    }

}
