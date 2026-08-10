package com.shoppingmall.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;

/** ORDER_STATUS 그룹의 code 값 (예: ORST0003 배송중). */
public record UpdateOrderStatusRequest(@NotBlank String statusCode) {
}
