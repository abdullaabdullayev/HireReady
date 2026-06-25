package com.hireready.document.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Service
public class TextExtractor {

    public String extract(String fileName, InputStream stream) {
        String name = fileName == null ? "" : fileName.toLowerCase(Locale.ROOT);
        try {
            if (name.endsWith(".pdf")) return extractPdf(stream);
            if (name.endsWith(".docx")) return extractDocx(stream);
            if (name.endsWith(".txt") || name.endsWith(".md")) {
                return new String(stream.readAllBytes(), StandardCharsets.UTF_8).trim();
            }
            return "";
        } catch (IOException e) {
            return "";
        }
    }

    public String extractPdf(InputStream stream) {
        try (PDDocument doc = Loader.loadPDF(stream.readAllBytes())) {
            return new PDFTextStripper().getText(doc).trim();
        } catch (IOException e) {
            return "";
        }
    }

    private String extractDocx(InputStream stream) throws IOException {
        try (ZipInputStream zip = new ZipInputStream(stream)) {
            ZipEntry entry;
            while ((entry = zip.getNextEntry()) != null) {
                if (!"word/document.xml".equals(entry.getName())) continue;
                String xml = new String(zip.readAllBytes(), StandardCharsets.UTF_8);
                return xml
                        .replaceAll("</w:p>", "\n")
                        .replaceAll("<[^>]+>", "")
                        .replace("&amp;", "&")
                        .replace("&lt;", "<")
                        .replace("&gt;", ">")
                        .replace("&quot;", "\"")
                        .replace("&apos;", "'")
                        .trim();
            }
        }
        return "";
    }
}
