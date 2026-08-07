package com.shoppingmall.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.security.autoconfigure.UserDetailsServiceAutoConfiguration;

// UserDetailsServiceAutoConfiguration 제외: 계정 인증은 AuthService가 accounts 테이블을 직접 조회해서
// 처리하고 Spring Security의 UserDetailsService/AuthenticationManager는 쓰지 않으므로,
// 기본 in-memory 사용자 자동 생성이 불필요하다 (그냥 두면 매 기동마다 안 쓰는 임시 비밀번호를 로그에 찍음).
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

}
