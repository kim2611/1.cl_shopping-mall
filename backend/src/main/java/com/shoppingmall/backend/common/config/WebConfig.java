package com.shoppingmall.backend.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.shoppingmall.backend.common.storage.LocalStorageService;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final LocalStorageService localStorageService;

    @Value("${app.storage.public-path}")
    private String publicPath;

    public WebConfig(LocalStorageService localStorageService) {
        this.localStorageService = localStorageService;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // LocalStorageService가 이미 해석해둔 절대경로를 그대로 쓴다 - 여기서 따로 또
        // user.dir 기준으로 다시 계산하면 둘이 서로 다른 경로를 가리킬 수 있다 (겪은 버그).
        String location = "file:" + localStorageService.getRootDir() + "/";
        registry.addResourceHandler(publicPath + "/**").addResourceLocations(location);
    }
}
