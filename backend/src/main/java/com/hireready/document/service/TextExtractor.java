package com.hireready.document.service;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;

@Service
public class TextExtractor {

    public String extractPdf(InputStream stream) {
        try (PDDocument doc = Loader.loadPDF(stream.readAllBytes())) {
            return new PDFTextStripper().getText(doc).trim();
        } catch (IOException e) {
            return "";
        }
    }
}
