# 1.shopping-mall

쇼핑몰 프로젝트. 백엔드(Spring Boot) + 모바일 앱(Expo/React Native) + 웹(Next.js, 미착수) +
설계 문서로 구성.

## 빠른 시작 (이미 인프라가 떠 있는 경우)

```bash
# 백엔드 (VM의 Postgres가 떠 있어야 함)
cd backend && ./gradlew bootRun
# → http://localhost:8090/docs (Swagger UI), 테스트 로그인: admin@mall.test / Mall!2026

# 모바일 앱
cd mobile && npm install && npx expo start --web
# → http://localhost:8081
```

## 새 머신에서 처음부터 세팅하는 경우

VirtualBox + Ubuntu VM만 있는 상태에서 전체 개발 환경을 재현하는 절차는
[document/06-배포운영/개발환경-세팅.md](document/06-배포운영/개발환경-세팅.md) 참고.

## 폴더 구조

| 폴더 | 내용 |
|---|---|
| `backend/` | Spring Boot API (Java 21, Gradle, PostgreSQL, JWT 인증) |
| `frontend/` | Next.js 웹 (스캐폴딩만, 아직 미착수) |
| `mobile/` | Expo(React Native) 앱 — 진행 중 |
| `document/` | 기획/요구사항/설계(ERD)/개발로그/테스트/배포운영 문서 |
| `infra/` | 로컬 개발 인프라(PostgreSQL + Jenkins) Docker Compose 정의 |

## 문서

- 설계 전체: [document/03-설계/ERD.md](document/03-설계/ERD.md), 스키마 원본은
  [document/03-설계/schema.sql](document/03-설계/schema.sql)
- 진행 이력: [document/04-개발/개발-로그.md](document/04-개발/개발-로그.md)
- 인프라: [document/06-배포운영/인프라.md](document/06-배포운영/인프라.md)
