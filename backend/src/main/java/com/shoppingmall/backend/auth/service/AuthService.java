package com.shoppingmall.backend.auth.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.shoppingmall.backend.account.entity.Account;
import com.shoppingmall.backend.account.entity.AccountEmail;
import com.shoppingmall.backend.account.entity.GeneralAccount;
import com.shoppingmall.backend.account.repository.AccountEmailRepository;
import com.shoppingmall.backend.account.repository.AccountRepository;
import com.shoppingmall.backend.account.repository.GeneralAccountRepository;
import com.shoppingmall.backend.auth.dto.LoginRequest;
import com.shoppingmall.backend.auth.dto.LoginResponse;
import com.shoppingmall.backend.auth.dto.SignupRequest;
import com.shoppingmall.backend.code.entity.CommonCode;
import com.shoppingmall.backend.code.repository.CommonCodeRepository;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.security.JwtService;

@Service
public class AuthService {

    // 아래 셋은 V2__seed_dev_data.sql에서 시드되는 code 값. 앱 로직이 특정 공통코드 행을 지목해야 하는
    // 몇 안 되는 지점이라 이 서비스 안에서만 상수로 관리한다 (schema.sql의 "code 문자열을 앱에서 파싱해
    // 분기하지 않는다" 원칙에 대한 의도된 예외 - 실제로는 *_code_id FK로만 참조하고, 이 상수는 그
    // FK 값을 찾기 위한 code_group+code 조회 키일 뿐이다).
    private static final String ACTIVE_STATUS_CODE = "ACST0001";
    private static final String GENERAL_ACCOUNT_TYPE_CODE = "ACTP0002";
    private static final String DEFAULT_GENERAL_GRADE_CODE = "GGRD0001";

    private final AccountRepository accountRepository;
    private final AccountEmailRepository accountEmailRepository;
    private final GeneralAccountRepository generalAccountRepository;
    private final CommonCodeRepository commonCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            AccountRepository accountRepository,
            AccountEmailRepository accountEmailRepository,
            GeneralAccountRepository generalAccountRepository,
            CommonCodeRepository commonCodeRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {
        this.accountRepository = accountRepository;
        this.accountEmailRepository = accountEmailRepository;
        this.generalAccountRepository = generalAccountRepository;
        this.commonCodeRepository = commonCodeRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Account account = accountRepository.findByLoginEmail(request.email())
                .orElseThrow(() -> new ApiException(ErrorCode.INVALID_CREDENTIALS));

        if (!passwordEncoder.matches(request.password(), account.getPassword())) {
            throw new ApiException(ErrorCode.INVALID_CREDENTIALS);
        }

        if (!activeStatusCodeId().equals(account.getStatusCodeId())) {
            throw new ApiException(ErrorCode.ACCOUNT_SUSPENDED);
        }

        return issueTokens(account);
    }

    @Transactional
    public LoginResponse signup(SignupRequest request) {
        if (accountEmailRepository.existsByEmailAndDelYn(request.email(), "N")) {
            throw new ApiException(ErrorCode.DUPLICATE_EMAIL);
        }

        Account account = Account.builder()
                .password(passwordEncoder.encode(request.password()))
                .name(request.name())
                .accountTypeCodeId(requireCode("ACCOUNT_TYPE", GENERAL_ACCOUNT_TYPE_CODE).getId())
                .statusCodeId(activeStatusCodeId())
                .createdBy("self-signup")
                .build();
        account = accountRepository.save(account);

        AccountEmail accountEmail = AccountEmail.builder()
                .accountId(account.getId())
                .email(request.email())
                .primaryYn("Y")
                .createdBy("self-signup")
                .build();
        accountEmailRepository.save(accountEmail);

        GeneralAccount generalAccount = GeneralAccount.builder()
                .accountId(account.getId())
                .gradeCodeId(requireCode("GENERAL_GRADE", DEFAULT_GENERAL_GRADE_CODE).getId())
                .points(0)
                .createdBy("self-signup")
                .build();
        generalAccountRepository.save(generalAccount);

        return issueTokens(account);
    }

    private LoginResponse issueTokens(Account account) {
        String accessToken = jwtService.issueAccessToken(account.getId(), account.getAccountTypeCodeId());
        String refreshToken = jwtService.issueRefreshToken(account.getId(), account.getAccountTypeCodeId());

        return LoginResponse.builder()
                .accountId(account.getId())
                .name(account.getName())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .build();
    }

    private String activeStatusCodeId() {
        return requireCode("ACCOUNT_STATUS", ACTIVE_STATUS_CODE).getId();
    }

    private CommonCode requireCode(String codeGroup, String code) {
        return commonCodeRepository.findByCodeGroupAndCode(codeGroup, code)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR, codeGroup + "." + code + " 코드가 시드되어 있지 않습니다."));
    }
}
