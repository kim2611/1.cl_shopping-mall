import { redirect } from "next/navigation";

export default function Home() {
  // 이 프론트는 관리자 콘솔 전용이라 루트로 오면 바로 관리자 화면으로 보낸다
  // (구매자용 화면은 mobile/ 앱이 담당).
  redirect("/admin");
}
