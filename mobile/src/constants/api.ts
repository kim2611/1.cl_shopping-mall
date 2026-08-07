import { Platform } from 'react-native';

/**
 * 백엔드 개발 서버 주소. 웹 미리보기(브라우저)에서는 localhost로 바로 붙지만,
 * 실제 폰(Expo Go)에서 열 때는 localhost가 폰 자신을 가리키므로 이 머신의 LAN IP로 바꿔야 한다
 * (예: http://192.168.0.12:8090). Android 에뮬레이터는 10.0.2.2가 호스트 PC를 가리킨다.
 */
export const API_BASE_URL =
  Platform.OS === 'android' ? 'http://10.0.2.2:8090' : 'http://localhost:8090';
