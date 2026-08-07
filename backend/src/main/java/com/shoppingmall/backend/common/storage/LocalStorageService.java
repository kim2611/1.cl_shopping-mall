package com.shoppingmall.backend.common.storage;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.system.ApplicationHome;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class LocalStorageService implements StorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalStorageService.class);

    private final Path rootDir;
    private final String publicPath;

    public LocalStorageService(
            @Value("${app.storage.local-dir}") String localDir,
            @Value("${app.storage.public-path}") String publicPath) {
        this.rootDir = resolveRootDir(localDir);
        this.publicPath = publicPath;

        if (Files.isDirectory(rootDir)) {
            log.info("Local storage root resolved to: {}", rootDir);
        } else {
            log.warn("Local storage root does not exist yet, will be created on first write: {}", rootDir);
        }
    }

    /**
     * app.storage.local-dir는 상대경로다. user.dir(프로세스 작업 디렉터리) 기준으로 풀면
     * IntelliJ Run과 ./gradlew bootRun이 서로 다른 작업 디렉터리를 쓸 때 실제로 다른 곳을
     * 가리키는 문제가 있었다 (겪은 버그). 대신 "이 앱이 실제로 로드된 위치"를 기준으로 푼다.
     * ApplicationHome.getDir()는 클래스패스 루트(예: backend/build/classes/java/main)를
     * 그대로 반환할 뿐 모듈 루트까지 거슬러 올라가주지는 않으므로, Gradle의 표준 산출물
     * 폴더명인 "build"를 랜드마크로 찾아 그 상위(=모듈 루트)로 직접 되짚어 올라간다.
     */
    private Path resolveRootDir(String localDir) {
        Path configured = Path.of(localDir);
        if (configured.isAbsolute()) {
            return configured.normalize();
        }
        Path home = new ApplicationHome(LocalStorageService.class).getDir().toPath();
        return findModuleRoot(home).resolve(configured).normalize();
    }

    private Path findModuleRoot(Path homeDir) {
        Path candidate = homeDir;
        while (candidate != null && candidate.getFileName() != null
                && !candidate.getFileName().toString().equals("build")) {
            candidate = candidate.getParent();
        }
        // candidate가 "build"면 그 부모가 모듈 루트. 못 찾으면(패키징 방식이 예상과 다르면) 원래 값으로 폴백.
        return candidate != null ? candidate.getParent() : homeDir;
    }

    @Override
    public StoredFile store(MultipartFile file, String subDirectory) {
        try {
            String extension = extensionOf(file.getOriginalFilename());
            String fileName = UUID.randomUUID() + extension;
            String relativePath = "%s/%s/%s".formatted(subDirectory, LocalDate.now(), fileName);

            Path target = rootDir.resolve(relativePath).normalize();
            if (!target.startsWith(rootDir)) {
                throw new IllegalArgumentException("잘못된 저장 경로입니다.");
            }
            Files.createDirectories(target.getParent());
            file.transferTo(target);

            return new StoredFile(relativePath, file.getContentType(), file.getSize());
        } catch (IOException e) {
            throw new UncheckedIOException("파일 저장에 실패했습니다.", e);
        }
    }

    @Override
    public String publicUrl(String storedPath) {
        return publicPath + "/" + storedPath;
    }

    /** WebConfig가 정적 리소스 핸들러에 동일한 절대경로를 쓰기 위해 노출 (S3 등 다른 구현체엔 없는, 로컬 전용 메서드). */
    public Path getRootDir() {
        return rootDir;
    }

    private String extensionOf(String originalName) {
        if (originalName == null) {
            return "";
        }
        int dot = originalName.lastIndexOf('.');
        return dot >= 0 ? originalName.substring(dot) : "";
    }
}
