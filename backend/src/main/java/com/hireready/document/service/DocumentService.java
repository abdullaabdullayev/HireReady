package com.hireready.document.service;

import com.hireready.common.enums.DocumentType;
import com.hireready.common.enums.ExtractionStatus;
import com.hireready.document.Document;
import com.hireready.document.DocumentRepository;
import com.hireready.user.CustomUserDetails;
import com.hireready.user.User;
import com.hireready.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DocumentService {


    private final DocumentRepository docRepo;
    private final UserRepository userRepository;
    private final StorageService storageService;
    private final TextExtractor textExtractor;



    public Document upload(User user, MultipartFile file, DocumentType type) {

        String storageKey = storageService.store(file);

        Document doc = new Document();
        doc.setUser(user);
        doc.setType(type);
        doc.setName(file.getOriginalFilename());
        doc.setContentType(file.getContentType());
        doc.setSizeBytes(file.getSize());
        doc.setStorageKey(storageKey);

        if(type == DocumentType.QUESTIONS){
            String text = "";
            try(InputStream in = storageService.load(storageKey)){
                text = textExtractor.extractPdf(in);
            }catch(Exception ignored){}

            doc.setExtractedText(text);
            doc.setExtractionStatus(
                    text.isEmpty() ? ExtractionStatus.FAILED : ExtractionStatus.DONE
            );
        }else {
            doc.setExtractionStatus(ExtractionStatus.NOT_NEEDED);
        }
        return docRepo.save(doc);
    }

    public List<Document> getUserDocuments(User user) {
        return docRepo.findByUserId(user.getId());
    }

    public void deleteUserDocuments(UUID id, User user) {
        Document doc = docRepo.findById(id)
                .orElseThrow(()->new RuntimeException("Document not found"));

        if(!doc.getUser().getId().equals(user.getId())){
            throw new RuntimeException("Not your document");
        }

        storageService.delete(doc.getStorageKey());
        docRepo.delete(doc);
    }

    public User currentUser(CustomUserDetails principal){
        return userRepository.findById(principal.getUserId())
                .orElseThrow(()-> new RuntimeException("User not found"));
    }
}
