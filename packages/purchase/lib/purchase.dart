/// purchase
///
/// 인앱 결제, 상품 모델, 잠금 관리.
/// Google Play / App Store 결제 연동 패키지.
///
/// TODO: 아래 파일들을 새로 작성:
///   - lib/iap_manager.dart    - 인앱 결제 흐름 (구매 요청, 결과 수신, 복원)
///   - lib/product.dart        - 상품 모델 (ID, 가격, 설명)
///   - lib/lock_manager.dart   - 잠금/해제 상태 관리
///
/// 구현 시 참고:
///   - in_app_purchase 패키지의 purchaseStream 리스닝
///   - restorePurchases()로 재설치 후 결제 이력 복원
///   - PurchaseStatus.refunded 감지 → 잠금 재적용
library purchase;
