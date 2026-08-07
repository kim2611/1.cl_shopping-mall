@echo off
REM 이 머신에 JDK가 설치돼 있고 PATH 또는 JAVA_HOME으로 잡혀 있어야 한다 (버전은 몇이든
REM 상관없음 - build.gradle의 toolchain 설정이 컴파일용 JDK 21은 알아서 받아온다).
REM 설치 안 돼 있으면 backend/README.md 참고.
call "%~dp0gradlew.bat" bootRun --console=plain
