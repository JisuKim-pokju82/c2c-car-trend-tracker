// MOVO (모보) — Apple 감성의 C2C 모빌리티 중고거래 마켓플레이스 초기 데이터

const CATEGORIES = [
  {
    id: 'all',
    name: '전체 모빌리티',
    shortName: '전체',
    desc: '이동의 모든 순간을 위한 전체 매물',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7" rx="2"/><rect x="14" y="3" width="7" height="7" rx="2"/><rect x="3" y="14" width="7" height="7" rx="2"/><rect x="14" y="14" width="7" height="7" rx="2"/></svg>`
  },
  {
    id: 'ev-car',
    name: '전기차 · 자동차',
    shortName: '전기차·자동차',
    desc: '테슬라, EV, 시티카, 캠핑카 직거래',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 17h14v-5l-2-5H7L5 12v5Z"/><circle cx="7.5" cy="17.5" r="2"/><circle cx="16.5" cy="17.5" r="2"/><path d="M3 12h18"/></svg>`
  },
  {
    id: 'moto',
    name: '바이크 · 스쿠터',
    shortName: '바이크·스쿠터',
    desc: '베스파, 클래식 커브, 전기스쿠터, 투어러',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="5.5" cy="17.5" r="3"/><circle cx="18.5" cy="17.5" r="3"/><path d="M15 6h3l2 6h-4l-2-6Z"/><path d="M5.5 17.5 9 11h5l2 6.5"/></svg>`
  },
  {
    id: 'cycle',
    name: '자전거 · E-바이크',
    shortName: '자전거·E바이크',
    desc: '브롬톤, 로드바이크, 전기자전거, 미니벨로',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="18.5" cy="17.5" r="3.5"/><path d="M15 6a1 1 0 1 0 0-2 1 1 0 0 0 0 2Zm-3 11.5V14l-3-3 4-3 2 3h2"/></svg>`
  },
  {
    id: 'personal',
    name: '퍼스널 모빌리티',
    shortName: '킥보드·퍼스널',
    desc: '전동킥보드, 전동보드, 외발휠, 마이크로 이동수단',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M6 15.5V5h3"/><path d="M6 18h12l-2-5"/></svg>`
  },
  {
    id: 'parts-gear',
    name: '모빌리티 기어 · 파츠',
    shortName: '기어·파츠',
    desc: '루프박스, 하이엔드 헬멧, 충전기, 휠·악세서리',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9c.26.604.852.997 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"/></svg>`
  },
  {
    id: 'aero-marine',
    name: '드론 · 워터 · 레저',
    shortName: '드론·워터',
    desc: '항공 드론, 전동 서프보드, 카약, 레저 모빌리티',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2L15 9l7 3-7 3-3 7-3-7-7-3 7-3 3-7Z"/></svg>`
  }
];

const NEIGHBORHOODS = [
  '전체 지역',
  '성수동',
  '한남동',
  '압구정동',
  '역삼동',
  '판교동',
  '여의도동',
  '연남동',
  '잠실동'
];

const NLP_SUGGESTIONS = [
  {
    label: '출퇴근용 접이식 전기자전거 200만원 이하',
    query: '출퇴근용 가벼운 접이식 전기자전거 200만원 이하'
  },
  {
    label: '성수동 시승 가능한 스쿠터·바이크',
    query: '성수동 근처 시승 가능한 베스파나 스쿠터'
  },
  {
    label: '배터리 95% 이상 전기차·테슬라 캠핑용',
    query: '배터리 상태 좋은 테슬라 전기차 캠핑용'
  },
  {
    label: '입문용 S급 브롬톤·로드바이크',
    query: '초보자 입문용 S급 브롬톤이나 로드바이크'
  },
  {
    label: '동네 마실용 전동킥보드 100만원 이하',
    query: '동네 마실용 안전한 전동킥보드 100만원 이하'
  },
  {
    label: '캠핑용 루프박스·헬멧 기어',
    query: '캠핑용 루프박스나 정품 헬멧 기어'
  }
];

const PRESET_PHOTOS = {
  'ev-car': [
    'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=1000&q=85'
  ],
  'moto': [
    'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1591637333184-19aa84b3e01f?auto=format&fit=crop&w=1000&q=85'
  ],
  'cycle': [
    'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1571068316344-75bc76f77890?auto=format&fit=crop&w=1000&q=85'
  ],
  'personal': [
    'https://images.unsplash.com/photo-1593764592116-bfb2a97c642a?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1600359756098-8bc52195bbf4?auto=format&fit=crop&w=1000&q=85'
  ],
  'parts-gear': [
    'https://images.unsplash.com/photo-1558980664-3a031cf67ea8?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1000&q=85'
  ],
  'aero-marine': [
    'https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=1000&q=85',
    'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=1000&q=85'
  ]
};

const INITIAL_ITEMS = [
  {
    id: 'movo-101',
    title: '테슬라 모델 Y 롱레인지 화이트 (FSD 포함 · 무사고 1인 신조)',
    category: 'ev-car',
    price: 46500000,
    marketPriceMin: 45000000,
    marketPriceMax: 49500000,
    negotiable: true,
    status: 'selling', // selling | reserved | sold
    condition: 'S급',
    year: 2024,
    mileageKm: 11200,
    batteryHealth: 98,
    testRideAvailable: true,
    neighborhood: '성수동',
    distanceKm: 0.8,
    timeAgo: '14분 전',
    createdAt: 1730800000000,
    likes: 42,
    chats: 9,
    views: 618,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['전기차', '테슬라', '모델Y', '캠핑용', '차박', '무사고', '롱레인지', '배터리특A'],
    description: `지하 주차장 전용 완속 충전기로만 관리한 24년식 테슬라 모델 Y 롱레인지입니다.\n\n• 배터리 SOH 98% (테슬라 서비스센터 진단 완료)\n• 비흡연 1인 신조, 완전 무사고 (보험이력 0원)\n• 차박 및 주말 캠핑용 매트, 정품 월커넥터, 3D 매트 일체 함께 드립니다.\n• 성수동 카페거리 인근에서 직접 시승 및 리프트 확인 가능합니다.`,
    seller: {
      name: '일론성수',
      avatar: '⚡',
      mannerTemp: 46.8,
      verifiedLocation: '성수동 2가 인증 18회',
      responseRate: '99% (보통 3분 내 응답)',
      tradesCount: 24
    }
  },
  {
    id: 'movo-102',
    title: '브롬톤 C라인 익스플로어 6단 클라우드 블루 (전용 가방·랙 풀세트)',
    category: 'cycle',
    price: 2350000,
    marketPriceMin: 2250000,
    marketPriceMax: 2600000,
    negotiable: true,
    status: 'selling',
    condition: 'S급',
    year: 2025,
    mileageKm: 280,
    batteryHealth: null,
    testRideAvailable: true,
    neighborhood: '한남동',
    distanceKm: 1.4,
    timeAgo: '28분 전',
    createdAt: 1730799200000,
    likes: 31,
    chats: 6,
    views: 412,
    isLiked: true,
    images: [
      'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['브롬톤', '접이식자전거', '미니벨로', '출퇴근', '한강라이딩', '입문용', '영국정품'],
    description: `한강 산책과 가벼운 출퇴근용으로 구매했다가 실주행 300km 미만으로 실내 거치만 해둔 브롬톤 C라인 익스플로어 6단입니다.\n\n• 폴딩 부위 스크래치 보호 필름 시공 완료\n• 정품 프론트 캐리어 블록 + 브롬톤 보로 가방(22만원 상당) 포함\n• 지하철 연계 출퇴근이나 차량 트렁크 보관용으로 최고입니다.`,
    seller: {
      name: '한남라이더',
      avatar: '🚲',
      mannerTemp: 52.3,
      verifiedLocation: '한남동 인증 32회',
      responseRate: '100% (보통 1분 내 응답)',
      tradesCount: 41
    }
  },
  {
    id: 'movo-103',
    title: '베스파 프리마베라 125 ABS 크림화이트 (정품 탑박스·윈드스크린)',
    category: 'moto',
    price: 3650000,
    marketPriceMin: 3500000,
    marketPriceMax: 4100000,
    negotiable: true,
    status: 'selling',
    condition: 'A급',
    year: 2024,
    mileageKm: 2450,
    batteryHealth: null,
    testRideAvailable: true,
    neighborhood: '성수동',
    distanceKm: 0.5,
    timeAgo: '42분 전',
    createdAt: 1730798000000,
    likes: 27,
    chats: 5,
    views: 389,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['베스파', '스쿠터', '출퇴근', '마실용', '시승가능', '무슬립', '클래식바이크'],
    description: `성수동 카페 투어 및 근거리 출퇴근용으로 아껴 탄 베스파 프리마베라 125 ABS입니다.\n\n• 제자리 슬립(제꿍) 일절 없는 깔끔한 컨디션\n• 피아지오 정품 컬러 매칭 탑박스 & 숏 스크린 장착\n• 폐지 완료되어 서류 3장 바로 구비되어 있으며 성수역 인근 시승 환영합니다.`,
    seller: {
      name: '에스프레소모터',
      avatar: '🛵',
      mannerTemp: 41.2,
      verifiedLocation: '성수동 1가 인증 12회',
      responseRate: '95% (보통 5분 내 응답)',
      tradesCount: 15
    }
  },
  {
    id: 'movo-104',
    title: '벤모프(VanMoof) S5 어반 스마트 전기자전거 (출퇴근 끝판왕)',
    category: 'cycle',
    price: 1680000,
    marketPriceMin: 1650000,
    marketPriceMax: 2100000,
    negotiable: true,
    status: 'selling',
    condition: 'S급',
    year: 2025,
    mileageKm: 410,
    batteryHealth: 99,
    testRideAvailable: true,
    neighborhood: '판교동',
    distanceKm: 3.2,
    timeAgo: '1시간 전',
    createdAt: 1730796000000,
    likes: 38,
    chats: 11,
    views: 520,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1571068316344-75bc76f77890?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['전기자전거', 'E바이크', '출퇴근', '판교출퇴근', '스마트자전거', '접이식', '가벼운'],
    description: `애플 감성 디자인으로 유명한 어반 스마트 전기자전거입니다.\n\n• 터보 부스트 버튼으로 오르막길도 땀 한 방울 없이 주행 가능\n• 애플 나의 찾기(Find My) 공식 연동 모델\n• 배터리 효율 99%, 완충 시 최대 120km PAS 주행 가능\n• 200만원 이하 예산으로 프리미엄 출퇴근용 전기자전거 찾으시는 분께 강력 추천합니다.`,
    seller: {
      name: '판교프로덕트디자이너',
      avatar: '',
      mannerTemp: 49.5,
      verifiedLocation: '판교동 인증 27회',
      responseRate: '100% (보통 2분 내 응답)',
      tradesCount: 33
    }
  },
  {
    id: 'movo-105',
    title: '나인봇 맥스 G2 프로 전동킥보드 (서스펜션 탑재 · 헬멧 무료증정)',
    category: 'personal',
    price: 620000,
    marketPriceMin: 600000,
    marketPriceMax: 750000,
    negotiable: true,
    status: 'selling',
    condition: 'A급',
    year: 2025,
    mileageKm: 320,
    batteryHealth: 97,
    testRideAvailable: true,
    neighborhood: '역삼동',
    distanceKm: 1.9,
    timeAgo: '1시간 전',
    createdAt: 1730793000000,
    likes: 19,
    chats: 4,
    views: 274,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1593764592116-bfb2a97c642a?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['전동킥보드', '나인봇', '출퇴근', '마실용', '퍼스널모빌리티', '서스펜션'],
    description: `역삼역~집 구간(왕복 3km) 출퇴근 및 동네 마실용으로 사용한 나인봇 맥스 G2 정품입니다.\n\n• 앞/뒤 듀얼 서스펜션이 들어가 있어 노면 충격이 거의 없습니다.\n• 애플 Find My 등록 가능, 방향지시등 내장\n• 우천 주행 0회, 배터리 사이클 12회 미만으로 신품급입니다.`,
    seller: {
      name: '테헤란로러너',
      avatar: '🛴',
      mannerTemp: 39.4,
      verifiedLocation: '역삼동 인증 9회',
      responseRate: '92% (보통 10분 내 응답)',
      tradesCount: 11
    }
  },
  {
    id: 'movo-106',
    title: '스페셜라이즈드 에스웍스(S-Works) 타막 SL8 듀라에이스 Di2 (54사이즈)',
    category: 'cycle',
    price: 11800000,
    marketPriceMin: 11500000,
    marketPriceMax: 13200000,
    negotiable: false,
    status: 'reserved',
    condition: 'S급',
    year: 2025,
    mileageKm: 650,
    batteryHealth: 100,
    testRideAvailable: true,
    neighborhood: '압구정동',
    distanceKm: 1.1,
    timeAgo: '2시간 전',
    createdAt: 1730790000000,
    likes: 64,
    chats: 14,
    views: 890,
    isLiked: true,
    images: [
      'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['로드바이크', '에스웍스', '타막SL8', '자전거', '카본휠', '기변', '초경량'],
    description: `국내 정식 스페셜라이즈드 스토어 출고 에스웍스 타막 SL8 완차입니다.\n\n• 시마노 듀라에이스 R9270 12단 Di2 전동 구동계 + 양발 파워미터\n• 로발 라피드 CLX II 휠셋 (무게 6.6kg 세팅)\n• 낙차 및 체인 드롭 전무하며, 압구정 나들목 인근 직거래 가능합니다.`,
    seller: {
      name: '펠로톤압구정',
      avatar: '🏆',
      mannerTemp: 58.0,
      verifiedLocation: '압구정동 인증 45회',
      responseRate: '100% (보통 1분 내 응답)',
      tradesCount: 62
    }
  },
  {
    id: 'movo-107',
    title: '툴레(Thule) 모션 XT XL 루프박스 블랙 유광 + 윙바 엣지 풀세트',
    category: 'parts-gear',
    price: 890000,
    marketPriceMin: 850000,
    marketPriceMax: 1100000,
    negotiable: true,
    status: 'selling',
    condition: 'A급',
    year: 2024,
    mileageKm: null,
    batteryHealth: null,
    testRideAvailable: false,
    neighborhood: '잠실동',
    distanceKm: 2.6,
    timeAgo: '3시간 전',
    createdAt: 1730785000000,
    likes: 23,
    chats: 5,
    views: 310,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['루프박스', '툴레', '캠핑용', '차박', '모빌리티기어', 'SUV용품', '스키캐리어'],
    description: `가족 캠핑 및 겨울 스키 시즌용으로 장착했던 툴레 모션 XT XL(500L) 정품입니다.\n\n• 양방향 오픈 시스템 및 파워클릭 마운트로 5분 내 장착 완료\n• 지하주차장 진입 가능 높이(대부분 SUV 호환)\n• 직거래 시 구매자분 차량 루프에 직접 함께 장착해 드립니다.`,
    seller: {
      name: '잠실오토캠퍼',
      avatar: '🏕️',
      mannerTemp: 44.1,
      verifiedLocation: '잠실동 인증 19회',
      responseRate: '98% (보통 5분 내 응답)',
      tradesCount: 28
    }
  },
  {
    id: 'movo-108',
    title: 'DJI 매빅 3 Pro 시네(Cine) 콤보 + RC Pro 조종기 (비행 8회 미만)',
    category: 'aero-marine',
    price: 2750000,
    marketPriceMin: 2700000,
    marketPriceMax: 3200000,
    negotiable: true,
    status: 'selling',
    condition: 'S급',
    year: 2025,
    mileageKm: 18,
    batteryHealth: 100,
    testRideAvailable: true,
    neighborhood: '여의도동',
    distanceKm: 4.1,
    timeAgo: '4시간 전',
    createdAt: 1730780000000,
    likes: 34,
    chats: 7,
    views: 445,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['드론', 'DJI', '매빅3프로', '항공모빌리티', '레저', '배터리특A'],
    description: `핫셀블라드 트리플 카메라가 탑재된 DJI 매빅 3 Pro 플라이 모어 콤보입니다.\n\n• 인텔리전트 플라이트 배터리 3개 모두 충전 사이클 4회 이하 (효율 100%)\n• DJI 케어 리프레시 잔여 기간 8개월 양도 가능\n• 여의도 한강공원 드론공원에서 테스트 비행 후 직거래 가능합니다.`,
    seller: {
      name: '스카이뷰여의도',
      avatar: '🛸',
      mannerTemp: 47.9,
      verifiedLocation: '여의도동 인증 14회',
      responseRate: '97% (보통 3분 내 응답)',
      tradesCount: 19
    }
  },
  {
    id: 'movo-109',
    title: '혼다 슈퍼커브 110 민트 에디션 (키로수 1,100km · 초보자 입문 추천)',
    category: 'moto',
    price: 2150000,
    marketPriceMin: 2050000,
    marketPriceMax: 2400000,
    negotiable: true,
    status: 'selling',
    condition: 'S급',
    year: 2024,
    mileageKm: 1100,
    batteryHealth: null,
    testRideAvailable: true,
    neighborhood: '연남동',
    distanceKm: 3.5,
    timeAgo: '5시간 전',
    createdAt: 1730775000000,
    likes: 29,
    chats: 8,
    views: 360,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['슈퍼커브', '혼다', '바이크', '스쿠터', '입문용', '마실용', '출퇴근'],
    description: `클러치 레버가 없어 스쿠터처럼 쉽게 운전 가능한 혼다 코리아 정식 슈퍼커브 110입니다.\n\n• 연비 리터당 60km 이상의 압도적 경제성\n• 비상등 스위치, USB 고속충전 포트, 리어 크롬 캐리어 장착\n• 바이크 입문자분께 조작법 친절히 안내해 드립니다.`,
    seller: {
      name: '연남클래식기어',
      avatar: '🌿',
      mannerTemp: 43.6,
      verifiedLocation: '연남동 인증 21회',
      responseRate: '96% (보통 5분 내 응답)',
      tradesCount: 17
    }
  },
  {
    id: 'movo-110',
    title: '아라이(Arai) 라파이드 네오 풀페이스 헬멧 아이보리 (L사이즈 · 블루투스 포함)',
    category: 'parts-gear',
    price: 450000,
    marketPriceMin: 430000,
    marketPriceMax: 550000,
    negotiable: true,
    status: 'selling',
    condition: 'S급',
    year: 2025,
    mileageKm: null,
    batteryHealth: 100,
    testRideAvailable: false,
    neighborhood: '성수동',
    distanceKm: 0.7,
    timeAgo: '6시간 전',
    createdAt: 1730770000000,
    likes: 18,
    chats: 3,
    views: 215,
    isLiked: false,
    images: [
      'https://images.unsplash.com/photo-1558980664-3a031cf67ea8?auto=format&fit=crop&w=1200&q=85'
    ],
    tags: ['헬멧', '아라이', '라파이드네오', '모빌리티기어', '바이크용품', '정품'],
    description: `클래식 바이크와 베스파에 가장 잘 어울리는 아라이 라파이드 네오 정품 헬멧입니다.\n\n• 바라클라바 착용 후 3회만 사용하여 내피 신품 컨디션\n• 세나 50S 블루투스 브라켓 및 정품 스모크 쉴드(8만원 상당) 포함입니다.`,
    seller: {
      name: '모터클럽성수',
      avatar: '🪖',
      mannerTemp: 40.8,
      verifiedLocation: '성수동 2가 인증 11회',
      responseRate: '94% (보통 10분 내 응답)',
      tradesCount: 9
    }
  }
];

const INITIAL_CHATS = [
  {
    id: 'chat-1',
    itemId: 'movo-102',
    partnerName: '한남라이더',
    partnerAvatar: '🚲',
    partnerTemp: 52.3,
    partnerNeighborhood: '한남동',
    unreadCount: 1,
    updatedAt: '방금 전',
    messages: [
      {
        id: 'm-1',
        sender: 'me',
        text: '안녕하세요! 브롬톤 C라인 클라우드 블루 아직 거래 가능한가요?',
        time: '오후 5:42'
      },
      {
        id: 'm-2',
        sender: 'partner',
        text: '네 안녕하세요! 실내 보관 중이라 상태 정말 깨끗합니다. 직거래 원하시나요?',
        time: '오후 5:43'
      },
      {
        id: 'm-3',
        sender: 'partner',
        text: '오늘 저녁 한남더힐 앞 카페거리에서 직접 폴딩 상태랑 변속 테스트해보실 수 있어요 :)',
        time: '오후 5:44'
      }
    ]
  },
  {
    id: 'chat-2',
    itemId: 'movo-101',
    partnerName: '일론성수',
    partnerAvatar: '⚡',
    partnerTemp: 46.8,
    partnerNeighborhood: '성수동',
    unreadCount: 0,
    updatedAt: '32분 전',
    messages: [
      {
        id: 'm-10',
        sender: 'me',
        text: '모델 Y 배터리 SOH 진단서 사진 채팅으로 확인 가능할까요?',
        time: '오후 5:10'
      },
      {
        id: 'm-11',
        sender: 'partner',
        text: '반갑습니다! 테슬라 성수 서비스센터에서 지난주 점검받은 98% 리포트 보관 중입니다. 시승 오시면 앱 화면으로도 바로 보여드릴게요.',
        time: '오후 5:12'
      }
    ]
  },
  {
    id: 'chat-3',
    itemId: 'movo-104',
    partnerName: '판교프로덕트디자이너',
    partnerAvatar: '',
    partnerTemp: 49.5,
    partnerNeighborhood: '판교동',
    unreadCount: 0,
    updatedAt: '2시간 전',
    messages: [
      {
        id: 'm-20',
        sender: 'me',
        text: '벤모프 S5 애플 나의 찾기(Find My) 소유권 이전 바로 되나요?',
        time: '오후 3:20'
      },
      {
        id: 'm-21',
        sender: 'partner',
        text: '네! 만나서 직거래할 때 제 아이폰에서 즉시 페어링 해제하고 구매자분 계정으로 등록까지 도와드립니다.',
        time: '오후 3:22'
      }
    ]
  }
];
