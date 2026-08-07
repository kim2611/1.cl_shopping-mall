package com.shoppingmall.backend.common.storage;

import org.springframework.web.multipart.MultipartFile;

/**
 * 파일 저장 추상화 - 지금은 로컬 디스크(LocalStorageService)만 구현하지만, 배포 인프라가
 * 정해지면 S3/R2 구현체로 갈아끼울 수 있도록 인터페이스로 분리한다.
 */
public interface StorageService {

    /**
     * 파일을 저장하고, files.stored_path에 넣을 상대 경로를 반환한다.
     */
    StoredFile store(MultipartFile file, String subDirectory);

    /**
     * stored_path로부터 클라이언트가 접근 가능한 공개 URL을 만든다.
     */
    String publicUrl(String storedPath);

    record StoredFile(String storedPath, String mimeType, long sizeBytes) {
    }
}
