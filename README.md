# 4대 중고차 플랫폼 C2C 직거래(개인) 일별 동향 & RAW 데이터 트래커

매일 한국시간(KST) **오전 08:00 정각**에 GitHub Actions 클라우드 스케줄러가 자동으로 실행되어 4대 중고차 플랫폼의 개인 직거래 매물 데이터를 Apple-to-Apple 동일 기준으로 수집·기록합니다.

## 추적 대상 플랫폼 (4개사 직거래/개인)
1. **당근중고차** (`/kr/cars/` 개인 직거래 매물)
2. **케이카 (K Car 안심직거래)** (`market.kcar.com` C2C 직거래 매물)
3. **엔카닷컴** (`Separation.A` 판매자구분 = 개인 매물, 국산/수입 분리)
4. **KB차차차** (`directYn=Y` 판매자구분 = 직거래(개인) 매물, 국산/수입 분리)

## 주요 산출물 및 바로가기
- **통합 웹 대시보드**: [`competitor_trend.html`](./competitor_trend.html)
  - Daily(일간) / Weekly(주간) / Monthly(월간) 조회 기간 전환
  - 전체 / 국산차 / 수입차 Apple-to-Apple 비교
  - 회사별 포트폴리오 비교 (국산/수입 비중, 판매가격대 분포, 지역 분포, 인기 모델 Top 10, 인기 브랜드 Top 8)
  - 개별 매물 RAW 데이터 검색 및 원클릭 CSV 다운로드
- **일자별 4개사 요약 누적 CSV**: [`competitor_trend.csv`](./competitor_trend.csv)
- **개별 매물 상세 RAW 데이터 폴더**: [`raw_data/`](./raw_data/)
  - [`raw_data/raw_vehicles_latest.csv`](./raw_data/raw_vehicles_latest.csv): 최신 개별 매물 통합 상세 RAW 데이터
- **일별 고유 매물 ID 스냅샷 폴더**: [`snapshots/`](./snapshots/) (일자별 신규등록·신규판매·회전율 산출용)
