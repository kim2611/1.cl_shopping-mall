package com.shoppingmall.backend.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 장바구니에 담긴 것 전체를 주문한다. 배송지는 여기서 받은 값을 orders에 스냅샷으로 저장한다
 * (저장된 주소를 골라 보냈다면 addressId도 같이 주면 "어디서 복사했는지" 역참조로 남는다).
 */
public record CreateOrderRequest(
        String addressId,
        @NotBlank @Size(max = 50) String recipientName,
        @NotBlank @Size(max = 20) String phone,
        @NotBlank @Size(max = 10) String zipCode,
        @NotBlank @Size(max = 200) String address1,
        @Size(max = 200) String address2,
        String paymentMethodCode) {
}
