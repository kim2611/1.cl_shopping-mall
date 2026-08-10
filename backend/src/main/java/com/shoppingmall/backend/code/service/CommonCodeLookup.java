package com.shoppingmall.backend.code.service;

import org.springframework.stereotype.Service;

import com.shoppingmall.backend.code.entity.CommonCode;
import com.shoppingmall.backend.code.repository.CommonCodeRepository;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;

/**
 * "code_group + code로 common_codes.id(FK 값)를 찾는" 조회를 한 곳에 모은다.
 * 앱이 code 문자열을 파싱해 분기하지는 않고(프로젝트 규칙), 어떤 코드 행을 가리킬지 지정할 때만 쓴다.
 */
@Service
public class CommonCodeLookup {

    private final CommonCodeRepository commonCodeRepository;

    public CommonCodeLookup(CommonCodeRepository commonCodeRepository) {
        this.commonCodeRepository = commonCodeRepository;
    }

    public CommonCode require(String codeGroup, String code) {
        return commonCodeRepository.findByCodeGroupAndCode(codeGroup, code)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR, codeGroup + "." + code + " 코드가 시드되어 있지 않습니다."));
    }

    public String requireId(String codeGroup, String code) {
        return require(codeGroup, code).getId();
    }
}
