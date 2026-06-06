package com.hireready.document.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.InputStream;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class StorageService {

    private final S3Client r2Client;

    @Value("${app.storage.r2.bucket}")
    private String bucket;

    public String store(MultipartFile file) {

        try {

            String originalFilename = file.getOriginalFilename();
            String ext = (originalFilename != null && originalFilename.contains("."))
                    ? originalFilename.substring(originalFilename.lastIndexOf(".")) : "";
            String key = UUID.randomUUID() + ext;

            r2Client.putObject(PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .build(),
                    RequestBody.fromInputStream(file.getInputStream(), file.getSize())
            );
            return key;
        }catch (Exception e){
            throw new RuntimeException("Could not upload file to R2", e);
        }
    }

    public InputStream load(String storageKey) {
        return  r2Client.getObject(
                GetObjectRequest.builder().bucket(bucket).key(storageKey).build()
        );
    }

    public void delete(String storageKey) {
        r2Client.deleteObject(b -> b.bucket(bucket).key(storageKey));
    }
}
