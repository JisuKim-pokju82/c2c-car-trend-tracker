// ==========================================================================
// MOVO (모보) — Apple Aesthetic x Daangn C2C Mobility Marketplace Controller
// ==========================================================================

const STORAGE_KEYS = {
  ITEMS: 'movo_items_v1',
  CHATS: 'movo_chats_v1'
};

const state = {
  items: [],
  chats: [],
  activeCategory: 'all',
  activeNeighborhood: '전체 지역',
  nlpQuery: '',
  parsedNlp: null,
  onlyAvailable: false,
  onlyTestRide: false,
  onlyNegotiable: false,
  onlyLiked: false,
  sortBy: 'latest',
  viewMode: 'grid', // 'grid' | 'list'
  activeDetailItemId: null,
  activeChatId: null,
  regPhotos: []
};

// --------------------------------------------------------------------------
// Utilities: Currency & Formatting
// --------------------------------------------------------------------------
function formatPriceWon(price) {
  if (!price || price === 0) return '나눔 (0원)';
  if (price >= 100000000) {
    const eok = Math.floor(price / 100000000);
    const man = Math.round((price % 100000000) / 10000);
    return man > 0 ? `${eok}억 ${man.toLocaleString('ko-KR')}만 원` : `${eok}억 원`;
  }
  if (price >= 10000000) {
    const man = Math.round(price / 10000);
    return `${man.toLocaleString('ko-KR')}만 원`;
  }
  return `${price.toLocaleString('ko-KR')}원`;
}

function formatKoreanCurrencyHelper(price) {
  const num = Number(price);
  if (!num || num <= 0) return '₩ 0원 (나눔 가능)';
  const man = Math.floor(num / 10000);
  const rest = num % 10000;
  let kor = '';
  if (man >= 10000) {
    const eok = Math.floor(man / 10000);
    const remMan = man % 10000;
    kor = `${eok}억 ${remMan > 0 ? remMan.toLocaleString() + '만' : ''} 원`;
  } else if (man > 0) {
    kor = `${man.toLocaleString()}만 ${rest > 0 ? rest.toLocaleString() : ''}원`;
  } else {
    kor = `${num.toLocaleString()}원`;
  }
  return `₩ ${kor} (${num.toLocaleString('ko-KR')}원)`;
}

function getCategoryObj(catId) {
  return CATEGORIES.find((c) => c.id === catId) || CATEGORIES[0];
}

function showToast(message) {
  const container = document.getElementById('toastContainer');
  if (!container) return;
  const pill = document.createElement('div');
  pill.className = 'toast-pill';
  pill.textContent = message;
  container.appendChild(pill);
  setTimeout(() => {
    pill.style.opacity = '0';
    pill.style.transition = 'opacity 0.25s ease';
    setTimeout(() => pill.remove(), 260);
  }, 2600);
}

// --------------------------------------------------------------------------
// Persistence
// --------------------------------------------------------------------------
function loadState() {
  try {
    const savedItems = localStorage.getItem(STORAGE_KEYS.ITEMS);
    state.items = savedItems ? JSON.parse(savedItems) : structuredClone(INITIAL_ITEMS);
  } catch {
    state.items = structuredClone(INITIAL_ITEMS);
  }

  try {
    const savedChats = localStorage.getItem(STORAGE_KEYS.CHATS);
    state.chats = savedChats ? JSON.parse(savedChats) : structuredClone(INITIAL_CHATS);
  } catch {
    state.chats = structuredClone(INITIAL_CHATS);
  }
  state.activeChatId = state.chats[0]?.id || null;
}

function saveItems() {
  try {
    localStorage.setItem(STORAGE_KEYS.ITEMS, JSON.stringify(state.items));
  } catch {
    // Ignore storage quota issues
  }
}

function saveChats() {
  try {
    localStorage.setItem(STORAGE_KEYS.CHATS, JSON.stringify(state.chats));
  } catch {
    // Ignore
  }
}

// --------------------------------------------------------------------------
// Natural Language Search Engine (자연어 검색 파서)
// --------------------------------------------------------------------------
function parseNaturalLanguageQuery(rawQuery) {
  const q = rawQuery.trim();
  if (!q) return null;

  const result = {
    raw: q,
    inferredCategories: [],
    maxPrice: null,
    minPrice: null,
    neighborhood: null,
    requireTestRide: false,
    requireConditionS: false,
    requireHighBattery: false,
    intentKeywords: [],
    tokens: []
  };

  // 1. Price parsing (e.g., "200만원 이하", "100만원대", "50만원", "5천만원 이하")
  const manMatch = q.match(/(\d+)\s*만\s*원?\s*(이하|미만|까지|대|안쪽)?/);
  const cheonManMatch = q.match(/(\d+)\s*천만\s*원?\s*(이하|미만|까지)?/);
  if (cheonManMatch) {
    const val = parseInt(cheonManMatch[1], 10) * 10000000;
    result.maxPrice = val;
    result.tokens.push({ label: '예산 상한', value: `${cheonManMatch[1]}천만 원 이하` });
  } else if (manMatch) {
    const val = parseInt(manMatch[1], 10) * 10000;
    const suffix = manMatch[2] || '이하';
    if (suffix === '대') {
      result.minPrice = val * 0.7;
      result.maxPrice = val * 1.9;
      result.tokens.push({ label: '예산 범위', value: `${manMatch[1]}만 원대` });
    } else {
      result.maxPrice = val;
      result.tokens.push({ label: '예산 상한', value: `${manMatch[1]}만 원 이하` });
    }
  }

  // 2. Neighborhood parsing
  for (const hood of NEIGHBORHOODS) {
    if (hood === '전체 지역') continue;
    const shortHood = hood.replace('동', '');
    if (q.includes(hood) || q.includes(shortHood)) {
      result.neighborhood = hood;
      result.tokens.push({ label: '희망 동네', value: hood });
      break;
    }
  }

  // 3. Category inference
  const catRules = [
    { id: 'cycle', words: ['전기자전거', '자전거', '브롬톤', '로드바이크', '로드', '미니벨로', '에스웍스', '벤모프', 'e바이크'] },
    { id: 'moto', words: ['베스파', '스쿠터', '바이크', '오토바이', '슈퍼커브', '커브', '혼다'] },
    { id: 'ev-car', words: ['테슬라', '전기차', '모델y', '모델3', '자동차', '차박', 'suv'] },
    { id: 'personal', words: ['전동킥보드', '킥보드', '나인봇', '퍼스널', '외발휠', '전동보드'] },
    { id: 'parts-gear', words: ['루프박스', '툴레', '헬멧', '아라이', '기어', '파츠', '용품', '캐리어'] },
    { id: 'aero-marine', words: ['드론', '매빅', 'dji', '서프보드', '보트', '카약'] }
  ];

  for (const rule of catRules) {
    if (rule.words.some((w) => q.toLowerCase().includes(w))) {
      result.inferredCategories.push(rule.id);
      const catName = getCategoryObj(rule.id).shortName;
      result.tokens.push({ label: '모빌리티 분류', value: catName });
    }
  }

  // 4. Condition & Feature intents
  if (q.includes('시승')) {
    result.requireTestRide = true;
    result.tokens.push({ label: '거래 조건', value: '시승 가능' });
  }
  if (q.toUpperCase().includes('S급') || q.includes('신품급') || q.includes('상태 좋은')) {
    result.requireConditionS = true;
    result.tokens.push({ label: '상태 등급', value: 'S급/최상급 우선' });
  }
  if (q.includes('배터리')) {
    result.requireHighBattery = true;
    result.tokens.push({ label: '배터리 진단', value: '고효율 배터리' });
  }

  // 5. Usage / Lifestyle keywords
  const stopWords = [
    '근처', '가능한', '이하', '미만', '원', '만원', '천만원', '찾아줘', '추천',
    '있는', '좋은', '상태', '이나', '나', '또는', '거', '것', '용', '동네', '안전한', '가벼운'
  ];
  const rawWords = q
    .replace(/(\d+)\s*(천)?만\s*원?\s*(이하|미만|까지|대)?/g, ' ')
    .split(/[\s,·/]+/)
    .map((w) => w.replace(/(이나|으로|에서|용으로|용|근처|가능한|상태)$/g, '').trim())
    .filter((w) => w.length >= 2 && !stopWords.includes(w));

  result.intentKeywords = [...new Set(rawWords)];
  if (result.intentKeywords.length > 0) {
    result.tokens.push({
      label: '핵심 키워드',
      value: result.intentKeywords.slice(0, 4).join(' · ')
    });
  }

  return result;
}

// --------------------------------------------------------------------------
// Filtering & Sorting Pipeline
// --------------------------------------------------------------------------
function getFilteredAndSortedItems() {
  let list = [...state.items];

  // 1. Category filter
  if (state.activeCategory !== 'all') {
    list = list.filter((item) => item.category === state.activeCategory);
  }

  // 2. Header Neighborhood filter
  if (state.activeNeighborhood !== '전체 지역') {
    list = list.filter((item) => item.neighborhood === state.activeNeighborhood);
  }

  // 3. Quick toggles
  if (state.onlyAvailable) {
    list = list.filter((item) => item.status === 'selling');
  }
  if (state.onlyTestRide) {
    list = list.filter((item) => item.testRideAvailable);
  }
  if (state.onlyNegotiable) {
    list = list.filter((item) => item.negotiable);
  }
  if (state.onlyLiked) {
    list = list.filter((item) => item.isLiked);
  }

  // 4. Natural Language Search filter & semantic scoring
  if (state.parsedNlp) {
    const nlp = state.parsedNlp;

    list = list
      .map((item) => {
        let score = 0;
        const searchableText = [
          item.title,
          item.description,
          item.neighborhood,
          item.condition,
          getCategoryObj(item.category).name,
          ...(item.tags || [])
        ]
          .join(' ')
          .toLowerCase();

        // Hard filter on budget ceiling if specified
        if (nlp.maxPrice !== null && item.price > nlp.maxPrice) {
          return { item, score: -1 };
        }
        if (nlp.minPrice !== null && item.price < nlp.minPrice) {
          return { item, score: -1 };
        }

        // Hard filter on neighborhood if explicitly mentioned in NLP query
        if (nlp.neighborhood && item.neighborhood !== nlp.neighborhood) {
          return { item, score: -1 };
        }

        // Hard filter on inferred category if any matched
        if (nlp.inferredCategories.length > 0) {
          if (nlp.inferredCategories.includes(item.category)) {
            score += 40;
          } else {
            return { item, score: -1 };
          }
        }

        if (nlp.requireTestRide) {
          if (item.testRideAvailable) score += 20;
          else return { item, score: -1 };
        }

        if (nlp.requireConditionS && item.condition === 'S급') {
          score += 15;
        }

        if (nlp.requireHighBattery && item.batteryHealth && item.batteryHealth >= 95) {
          score += 20;
        }

        // Keyword matching
        let matchedWords = 0;
        for (const kw of nlp.intentKeywords) {
          if (searchableText.includes(kw.toLowerCase())) {
            score += 18;
            matchedWords++;
          }
        }

        // If no structured constraints matched at all, require at least one keyword hit
        const hasStructuredMatch =
          nlp.inferredCategories.length > 0 ||
          nlp.maxPrice !== null ||
          nlp.neighborhood !== null ||
          nlp.requireTestRide;

        if (!hasStructuredMatch && matchedWords === 0) {
          return { item, score: -1 };
        }

        return { item, score };
      })
      .filter((entry) => entry.score >= 0)
      .sort((a, b) => b.score - a.score)
      .map((entry) => entry.item);
  }

  // 5. Sorting (when not overridden or as secondary sort)
  if (!state.parsedNlp) {
    list.sort((a, b) => {
      if (state.sortBy === 'popular') return b.likes - a.likes;
      if (state.sortBy === 'price-asc') return a.price - b.price;
      if (state.sortBy === 'price-desc') return b.price - a.price;
      if (state.sortBy === 'mileage-asc') {
        const ma = a.mileageKm ?? 999999;
        const mb = b.mileageKm ?? 999999;
        return ma - mb;
      }
      return b.createdAt - a.createdAt;
    });
  }

  return list;
}

// --------------------------------------------------------------------------
// UI Rendering: Header, Categories, NLP Banner & Listing Cards
// --------------------------------------------------------------------------
function renderNeighborhoodSelect() {
  const select = document.getElementById('neighborhoodSelect');
  if (!select) return;
  select.innerHTML = NEIGHBORHOODS.map(
    (hood) => `<option value="${hood}" ${hood === state.activeNeighborhood ? 'selected' : ''}>${hood}</option>`
  ).join('');
}

function renderNlpSuggestionChips() {
  const row = document.getElementById('nlpChipsRow');
  if (!row) return;
  const chipsHtml = NLP_SUGGESTIONS.map(
    (s) => `<button type="button" class="nlp-chip" data-nlp-query="${s.query}">${s.label}</button>`
  ).join('');
  row.innerHTML = `<span class="nlp-chip-label">추천 자연어 검색</span>${chipsHtml}`;
}

function renderNlpInsightBanner() {
  const banner = document.getElementById('nlpInsightBanner');
  const tagsBox = document.getElementById('nlpParsedTags');
  const clearBtn = document.getElementById('nlpClearBtn');
  if (!banner || !tagsBox) return;

  if (clearBtn) {
    clearBtn.classList.toggle('visible', Boolean(state.nlpQuery));
  }

  if (!state.parsedNlp) {
    banner.classList.remove('active');
    return;
  }

  banner.classList.add('active');
  const tokensHtml = state.parsedNlp.tokens
    .map((t) => `<span class="nlp-token">${t.label}: <strong>${t.value}</strong></span>`)
    .join('');

  tagsBox.innerHTML = `
    <span class="nlp-parsed-title">✨ 자연어 분석 결과</span>
    ${tokensHtml}
  `;
}

function renderCategories() {
  const dock = document.getElementById('categoryDock');
  if (!dock) return;

  dock.innerHTML = CATEGORIES.map((cat) => {
    const count =
      cat.id === 'all'
        ? state.items.length
        : state.items.filter((i) => i.category === cat.id).length;
    const isActive = state.activeCategory === cat.id;
    return `
      <button type="button" class="category-card ${isActive ? 'active' : ''}" data-category-id="${cat.id}">
        <div class="category-icon-box">${cat.icon}</div>
        <span class="category-name">${cat.shortName}</span>
        <span class="category-count">${count}대</span>
      </button>
    `;
  }).join('');
}

function renderHeaderBadges() {
  const wishCount = state.items.filter((i) => i.isLiked).length;
  const wishBadge = document.getElementById('wishCountBadge');
  const wishBtn = document.getElementById('wishlistFilterBtn');
  if (wishBadge) wishBadge.textContent = wishCount;
  if (wishBtn) wishBtn.classList.toggle('active', state.onlyLiked);

  const unreadTotal = state.chats.reduce((acc, c) => acc + (c.unreadCount || 0), 0);
  const chatBadge = document.getElementById('unreadChatBadge');
  if (chatBadge) {
    chatBadge.textContent = unreadTotal;
    chatBadge.style.display = unreadTotal > 0 ? 'inline-flex' : 'none';
  }
}

function buildSpecOverlayText(item) {
  const parts = [];
  if (item.year) parts.push(`${item.year}년식`);
  if (item.mileageKm !== null && item.mileageKm !== undefined) {
    parts.push(`${Number(item.mileageKm).toLocaleString()}km`);
  }
  if (item.batteryHealth) {
    parts.push(`배터리 ${item.batteryHealth}%`);
  }
  return parts.join(' · ') || '정품 인증 매물';
}

function renderItems() {
  const container = document.getElementById('itemsContainer');
  const titleEl = document.getElementById('currentCategoryTitle');
  const countEl = document.getElementById('resultCountText');
  if (!container) return;

  container.classList.toggle('list-mode', state.viewMode === 'list');

  const filtered = getFilteredAndSortedItems();
  const catObj = getCategoryObj(state.activeCategory);

  if (titleEl) {
    if (state.onlyLiked) {
      titleEl.textContent = '내가 찜한 모빌리티';
    } else if (state.parsedNlp) {
      titleEl.textContent = `'${state.parsedNlp.raw}' 맞춤 매물`;
    } else {
      titleEl.textContent = catObj.name;
    }
  }
  if (countEl) {
    countEl.textContent = `${filtered.length}개 매물`;
  }

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <h3>조건에 맞는 모빌리티 매물이 없습니다</h3>
        <p>자연어 검색어나 카테고리·필터 조건을 완화해 다시 탐색해 보세요.</p>
        <button type="button" class="btn-register-primary" id="emptyResetBtn">전체 모빌리티 보기</button>
      </div>
    `;
    document.getElementById('emptyResetBtn')?.addEventListener('click', resetAllFilters);
    return;
  }

  container.innerHTML = filtered
    .map((item) => {
      const cat = getCategoryObj(item.category);
      const specText = buildSpecOverlayText(item);
      const statusLabel =
        item.status === 'reserved'
          ? `<span class="status-badge reserved">예약중</span>`
          : item.status === 'sold'
          ? `<span class="status-badge sold">거래완료</span>`
          : '';

      return `
        <article class="item-card" data-item-id="${item.id}">
          <div class="card-thumb-wrap">
            <img
              src="${item.images[0]}"
              alt="${item.title}"
              class="card-thumb-img"
              loading="lazy"
            />
            <div class="thumb-badges-top">
              ${statusLabel}
              <span class="status-badge condition">${item.condition}</span>
              ${item.testRideAvailable ? `<span class="status-badge testride">시승가능</span>` : ''}
            </div>

            <button
              type="button"
              class="card-like-btn ${item.isLiked ? 'liked' : ''}"
              data-like-id="${item.id}"
              aria-label="찜하기"
              title="관심 모빌리티 찜하기"
            >
              <svg viewBox="0 0 24 24" fill="${item.isLiked ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2">
                <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
              </svg>
            </button>

            <div class="thumb-spec-bar">
              <span class="spec-overlay-pill">${specText}</span>
            </div>
          </div>

          <div class="card-body">
            <div>
              <div class="card-meta-top">
                <span class="card-category-tag">${cat.shortName}</span>
                <span class="card-location-time">${item.neighborhood} · ${item.timeAgo}</span>
              </div>
              <h3 class="card-title">${item.title}</h3>
              <div class="card-price-row">
                <span class="card-price">${formatPriceWon(item.price)}</span>
                ${item.negotiable ? `<span class="nego-pill">가격제안가능</span>` : ''}
              </div>
            </div>

            <div class="card-footer">
              <div class="seller-mini">
                <span>${item.seller.avatar} ${item.seller.name}</span>
                <span class="manner-chip">${item.seller.mannerTemp.toFixed(1)}°C</span>
              </div>
              <div class="card-stats">
                <span class="stat-item" title="관심 찜 수">♥ ${item.likes}</span>
                <span class="stat-item" title="채팅 수">💬 ${item.chats}</span>
              </div>
            </div>
          </div>
        </article>
      `;
    })
    .join('');
}

function renderAll() {
  renderNeighborhoodSelect();
  renderNlpInsightBanner();
  renderCategories();
  renderHeaderBadges();
  renderItems();
}

function resetAllFilters() {
  state.activeCategory = 'all';
  state.activeNeighborhood = '전체 지역';
  state.nlpQuery = '';
  state.parsedNlp = null;
  state.onlyAvailable = false;
  state.onlyTestRide = false;
  state.onlyNegotiable = false;
  state.onlyLiked = false;

  const nlpInput = document.getElementById('nlpMainInput');
  const headerInput = document.getElementById('headerSearchInput');
  if (nlpInput) nlpInput.value = '';
  if (headerInput) headerInput.value = '';

  document.getElementById('filterAvailableOnly').checked = false;
  document.getElementById('filterTestRideOnly').checked = false;
  document.getElementById('filterNegotiableOnly').checked = false;

  renderAll();
}

// --------------------------------------------------------------------------
// Wishlist (찜하기) Toggle
// --------------------------------------------------------------------------
function toggleLikeItem(itemId) {
  const item = state.items.find((i) => i.id === itemId);
  if (!item) return;

  item.isLiked = !item.isLiked;
  item.likes += item.isLiked ? 1 : -1;
  saveItems();
  renderHeaderBadges();
  renderItems();

  if (state.activeDetailItemId === itemId) {
    renderDetailModalContent(item);
  }

  showToast(
    item.isLiked
      ? `♥ '${item.title.slice(0, 18)}...' 매물을 찜 목록에 담았습니다.`
      : '찜 목록에서 해제했습니다.'
  );
}

// --------------------------------------------------------------------------
// Product Detail Modal
// --------------------------------------------------------------------------
function openDetailModal(itemId) {
  const item = state.items.find((i) => i.id === itemId);
  if (!item) return;
  state.activeDetailItemId = itemId;
  item.views = (item.views || 100) + 1;
  saveItems();

  renderDetailModalContent(item);
  const dialog = document.getElementById('detailDialog');
  if (dialog && !dialog.open) {
    dialog.showModal();
  }
}

function renderDetailModalContent(item) {
  const headerEl = document.getElementById('detailModalCategoryHeader');
  const contentEl = document.getElementById('detailModalContent');
  if (!contentEl) return;

  const cat = getCategoryObj(item.category);
  if (headerEl) {
    headerEl.textContent = `${cat.name} · ${item.neighborhood} 직거래`;
  }

  const mannerPercent = Math.min(100, Math.max(20, ((item.seller.mannerTemp - 30) / 35) * 100));
  const marketMin = item.marketPriceMin || Math.round(item.price * 0.94);
  const marketMax = item.marketPriceMax || Math.round(item.price * 1.08);

  const thumbsHtml =
    item.images.length > 1
      ? `<div class="detail-thumbs-row">
          ${item.images
            .map(
              (img, idx) => `
              <button type="button" class="detail-thumb-btn ${idx === 0 ? 'active' : ''}" data-gallery-src="${img}">
                <img src="${img}" alt="썸네일 ${idx + 1}" />
              </button>
            `
            )
            .join('')}
        </div>`
      : '';

  contentEl.innerHTML = `
    <div class="detail-grid">
      <!-- Left: Photo Gallery & Seller Trust Profile -->
      <div>
        <div class="detail-gallery-main">
          <img src="${item.images[0]}" alt="${item.title}" id="detailMainImage" />
        </div>
        ${thumbsHtml}

        <div class="seller-card">
          <div class="seller-profile-left">
            <div class="seller-avatar">${item.seller.avatar}</div>
            <div>
              <div class="seller-name">${item.seller.name}</div>
              <div class="seller-verified">${item.seller.verifiedLocation} · 거래 ${item.seller.tradesCount}회</div>
              <div class="seller-verified">${item.seller.responseRate}</div>
            </div>
          </div>
          <div class="manner-meter-box">
            <div class="manner-temp-val">${item.seller.mannerTemp.toFixed(1)}°C</div>
            <div class="manner-bar-track">
              <div class="manner-bar-fill" style="width: ${mannerPercent}%"></div>
            </div>
            <div style="font-size:0.68rem; color:var(--ink-muted); margin-top:2px;">매너온도</div>
          </div>
        </div>
      </div>

      <!-- Right: Mobility Specs, Price Control & Actions -->
      <div class="detail-info-col">
        <div class="detail-status-row">
          <div style="display:flex; gap:6px; align-items:center;">
            <select id="detailStatusSwitcher" class="status-select-inline" aria-label="거래 상태 변경">
              <option value="selling" ${item.status === 'selling' ? 'selected' : ''}>🟢 판매중</option>
              <option value="reserved" ${item.status === 'reserved' ? 'selected' : ''}>🟡 예약중</option>
              <option value="sold" ${item.status === 'sold' ? 'selected' : ''}>⚫ 거래완료</option>
            </select>
            <span style="font-size:0.78rem; color:var(--ink-muted);">${item.timeAgo} · 조회 ${item.views}</span>
          </div>
          <button type="button" class="preset-photo-btn" id="detailEditPriceBtn">판매가격 수정</button>
        </div>

        <h2 class="detail-title">${item.title}</h2>

        <div class="detail-price-box">
          <div class="detail-price-main">
            <span class="detail-price-number">${formatPriceWon(item.price)}</span>
            ${
              item.negotiable
                ? `<span class="nego-pill">가격 제안 환영</span>`
                : `<span style="font-size:0.75rem; color:var(--ink-muted); font-weight:600;">정찰가 판매</span>`
            }
          </div>
          <div class="market-compare-text">
            <span>동일 모델 중고 시세: ${formatPriceWon(marketMin)} ~ ${formatPriceWon(marketMax)}</span>
            <span class="market-good-badge">✓ 적정 시세 범위</span>
          </div>
        </div>

        <!-- Mobility Hardware Spec Bento -->
        <div class="spec-bento-grid">
          <div class="spec-bento-item">
            <div class="spec-bento-label">출고 연식 · 상태</div>
            <div class="spec-bento-value">${item.year ? item.year + '년식' : '연식 무관'} · ${item.condition}</div>
          </div>
          <div class="spec-bento-item">
            <div class="spec-bento-label">누적 주행거리</div>
            <div class="spec-bento-value">${
              item.mileageKm !== null && item.mileageKm !== undefined
                ? Number(item.mileageKm).toLocaleString() + ' km'
                : '비주행 기어/파츠'
            }</div>
          </div>
          <div class="spec-bento-item">
            <div class="spec-bento-label">배터리 효율 (SOH)</div>
            <div class="spec-bento-value">${
              item.batteryHealth ? item.batteryHealth + '% (진단 완료)' : '내연기관 / 무동력'
            }</div>
          </div>
          <div class="spec-bento-item">
            <div class="spec-bento-label">시승 · 직거래 동네</div>
            <div class="spec-bento-value">${item.neighborhood} (${item.testRideAvailable ? '시승 가능' : '직거래'})</div>
          </div>
        </div>

        <div class="detail-desc">${item.description}</div>

        <div class="detail-tags">
          ${(item.tags || []).map((t) => `<span class="detail-tag-chip">#${t}</span>`).join('')}
        </div>

        <div class="detail-cta-row">
          <button
            type="button"
            class="btn-wish-large ${item.isLiked ? 'liked' : ''}"
            id="detailLikeBtn"
            aria-label="찜하기"
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="${item.isLiked ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2">
              <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
            </svg>
          </button>

          <button type="button" class="btn-offer-secondary" id="detailOfferBtn">
            가격 제안하기
          </button>

          <button type="button" class="btn-chat-primary" id="detailStartChatBtn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
            </svg>
            <span>채팅으로 거래하기</span>
          </button>
        </div>
      </div>
    </div>
  `;

  // Thumbnail switcher inside detail modal
  contentEl.querySelectorAll('[data-gallery-src]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const mainImg = document.getElementById('detailMainImage');
      if (mainImg) mainImg.src = btn.dataset.gallerySrc;
      contentEl.querySelectorAll('.detail-thumb-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Status switcher
  document.getElementById('detailStatusSwitcher')?.addEventListener('change', (e) => {
    item.status = e.target.value;
    saveItems();
    renderItems();
    showToast(`거래 상태가 '${e.target.options[e.target.selectedIndex].text}'(으)로 변경되었습니다.`);
  });

  // Inline price edit
  document.getElementById('detailEditPriceBtn')?.addEventListener('click', () => {
    openOfferOrPriceEditModal(item, 'edit');
  });

  // Like button
  document.getElementById('detailLikeBtn')?.addEventListener('click', () => {
    toggleLikeItem(item.id);
  });

  // Offer button
  document.getElementById('detailOfferBtn')?.addEventListener('click', () => {
    openOfferOrPriceEditModal(item, 'offer');
  });

  // Start chat button
  document.getElementById('detailStartChatBtn')?.addEventListener('click', () => {
    document.getElementById('detailDialog')?.close();
    openChatForItem(item);
  });
}

// --------------------------------------------------------------------------
// Price Offer & Price Edit Modal
// --------------------------------------------------------------------------
let currentOfferMode = 'offer'; // 'offer' | 'edit'

function openOfferOrPriceEditModal(item, mode = 'offer') {
  currentOfferMode = mode;
  const dialog = document.getElementById('offerDialog');
  const summaryEl = document.getElementById('offerTargetSummary');
  const inputEl = document.getElementById('offerPriceInput');
  const modalTitle = dialog?.querySelector('.modal-title');
  const submitBtn = dialog?.querySelector('button[type="submit"]');

  if (!dialog || !summaryEl || !inputEl) return;

  if (mode === 'edit') {
    if (modalTitle) modalTitle.textContent = '판매가격 수정하기';
    if (submitBtn) submitBtn.textContent = '변경된 판매가격 저장하기';
  } else {
    if (modalTitle) modalTitle.textContent = '가격 제안하기 (네고 요청)';
    if (submitBtn) submitBtn.textContent = '채팅방으로 가격 제안 보내기';
  }

  summaryEl.innerHTML = `
    <div style="font-weight:700; margin-bottom:4px;">${item.title}</div>
    <div style="color:var(--ink-secondary);">현재 판매가: <strong style="color:var(--accent-blue);">${formatPriceWon(item.price)}</strong></div>
  `;
  inputEl.value = mode === 'edit' ? item.price : Math.round((item.price * 0.96) / 1000) * 1000;

  dialog.showModal();
}

// --------------------------------------------------------------------------
// Registration Modal (내 모빌리티 팔기)
// --------------------------------------------------------------------------
function renderRegisterPhotoPreviews() {
  const listEl = document.getElementById('photoPreviewList');
  const countLabel = document.getElementById('photoCountLabel');
  if (!listEl || !countLabel) return;

  countLabel.textContent = `${state.regPhotos.length} / 5`;
  listEl.innerHTML = state.regPhotos
    .map(
      (src, idx) => `
      <div class="photo-preview-item">
        <img src="${src}" alt="등록 사진 ${idx + 1}" />
        <button type="button" class="photo-remove-btn" data-remove-photo="${idx}" aria-label="사진 삭제">✕</button>
      </div>
    `
    )
    .join('');

  listEl.querySelectorAll('[data-remove-photo]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = Number(btn.dataset.removePhoto);
      state.regPhotos.splice(idx, 1);
      renderRegisterPhotoPreviews();
    });
  });
}

function addPresetPhotosForCurrentCategory() {
  const catId = document.getElementById('regCategory')?.value || 'cycle';
  const presets = PRESET_PHOTOS[catId] || PRESET_PHOTOS['cycle'];
  for (const url of presets) {
    if (state.regPhotos.length < 5 && !state.regPhotos.includes(url)) {
      state.regPhotos.push(url);
    }
  }
  renderRegisterPhotoPreviews();
  showToast('고화질 카테고리 샘플 사진이 자동으로 추가되었습니다.');
}

function generateAiMobilityDescription() {
  const catId = document.getElementById('regCategory')?.value || 'cycle';
  const catName = getCategoryObj(catId).name;
  const title = document.getElementById('regTitle')?.value || '프리미엄 모빌리티';
  const year = document.getElementById('regYear')?.value || '2025';
  const mileage = document.getElementById('regMileage')?.value || '300';
  const battery = document.getElementById('regBattery')?.value;
  const condition = document.getElementById('regCondition')?.value || 'S급';
  const hood = document.getElementById('regNeighborhood')?.value || '성수동';

  const descEl = document.getElementById('regDesc');
  if (!descEl) return;

  descEl.value = `[${catName}] ${title} 판매합니다.\n\n• 출고 연식: ${year}년식 (${condition} 컨디션)\n• 누적 주행거리: ${Number(mileage).toLocaleString()}km 실주행 보증${
    battery ? `\n• 배터리 효율(SOH): ${battery}% 점검 완료` : ''
  }\n• 실내 보관 위주로 관리하여 외관 및 구동계 상태 매우 깔끔합니다.\n• ${hood} 인근에서 직접 상태 확인 및 시승 후 기분 좋게 직거래 희망합니다.`;
  showToast('✨ 입력하신 스펙을 기반으로 상세 설명이 자동 작성되었습니다.');
}

// --------------------------------------------------------------------------
// Real-Time Mobility Chat (모빌리티 당근채팅)
// --------------------------------------------------------------------------
function openChatForItem(item, initialMessageText = null) {
  let chatRoom = state.chats.find((c) => c.itemId === item.id);

  if (!chatRoom) {
    chatRoom = {
      id: `chat-${Date.now()}`,
      itemId: item.id,
      partnerName: item.seller.name,
      partnerAvatar: item.seller.avatar,
      partnerTemp: item.seller.mannerTemp,
      partnerNeighborhood: item.neighborhood,
      unreadCount: 0,
      updatedAt: '방금 전',
      messages: [
        {
          id: `m-${Date.now()}-welcome`,
          sender: 'partner',
          text: `안녕하세요! '${item.title}' 매물에 관심 주셔서 감사합니다. 궁금하신 스펙이나 시승 일정 편하게 말씀해 주세요 :)`,
          time: '방금 전'
        }
      ]
    };
    state.chats.unshift(chatRoom);
    item.chats += 1;
    saveItems();
  }

  state.activeChatId = chatRoom.id;
  chatRoom.unreadCount = 0;

  if (initialMessageText) {
    appendChatMessage(chatRoom.id, 'me', initialMessageText);
  } else {
    saveChats();
    renderChatModal();
  }

  renderHeaderBadges();
  const chatDialog = document.getElementById('chatDialog');
  if (chatDialog && !chatDialog.open) {
    chatDialog.showModal();
  }
}

function renderChatModal() {
  const roomListEl = document.getElementById('chatRoomList');
  const bannerEl = document.getElementById('chatItemBanner');
  const messagesEl = document.getElementById('chatMessagesArea');
  if (!roomListEl || !bannerEl || !messagesEl) return;

  const activeChat = state.chats.find((c) => c.id === state.activeChatId) || state.chats[0];
  if (activeChat) {
    state.activeChatId = activeChat.id;
  }

  // 1. Render Left Room List
  roomListEl.innerHTML = state.chats
    .map((chat) => {
      const lastMsg = chat.messages[chat.messages.length - 1]?.text || '대화를 시작해 보세요.';
      const isActive = chat.id === state.activeChatId;
      return `
        <button type="button" class="chat-room-item ${isActive ? 'active' : ''}" data-chat-id="${chat.id}">
          <div class="chat-room-avatar">${chat.partnerAvatar}</div>
          <div class="chat-room-meta">
            <div class="chat-room-top">
              <span>${chat.partnerName} <small style="color:var(--daangn-warm); font-weight:700;">${chat.partnerTemp}°C</small></span>
              <span style="font-size:0.7rem; color:var(--ink-muted); font-weight:500;">${chat.updatedAt}</span>
            </div>
            <div class="chat-room-preview">${lastMsg}</div>
          </div>
        </button>
      `;
    })
    .join('');

  roomListEl.querySelectorAll('[data-chat-id]').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.activeChatId = btn.dataset.chatId;
      const room = state.chats.find((c) => c.id === state.activeChatId);
      if (room) room.unreadCount = 0;
      saveChats();
      renderHeaderBadges();
      renderChatModal();
    });
  });

  if (!activeChat) {
    bannerEl.innerHTML = '<div>진행 중인 대화가 없습니다.</div>';
    messagesEl.innerHTML = '';
    return;
  }

  const targetItem = state.items.find((i) => i.id === activeChat.itemId) || state.items[0];

  // 2. Render Top Item Banner inside Chat
  bannerEl.innerHTML = `
    <div class="chat-item-summary">
      <img src="${targetItem.images[0]}" alt="${targetItem.title}" class="chat-item-thumb" />
      <div style="min-width:0;">
        <div class="chat-item-title">${targetItem.title}</div>
        <div class="chat-item-price">${formatPriceWon(targetItem.price)} · ${targetItem.neighborhood}</div>
      </div>
    </div>
    <div class="chat-item-actions">
      <button type="button" class="chat-mini-action" id="chatBookTestRideBtn">📅 시승 약속 잡기</button>
      <button type="button" class="chat-mini-action" id="chatSafePayBtn">🛡️ 모빌리티 안심페이</button>
    </div>
  `;

  document.getElementById('chatBookTestRideBtn')?.addEventListener('click', () => {
    appendChatMessage(
      activeChat.id,
      'me',
      `[시승 예약 요청] 오늘 저녁 7시 ${targetItem.neighborhood}에서 직접 시승 및 상태 점검 가능할까요?`
    );
  });

  document.getElementById('chatSafePayBtn')?.addEventListener('click', () => {
    targetItem.status = 'reserved';
    saveItems();
    renderItems();
    appendChatMessage(
      activeChat.id,
      'me',
      `[MOVO 안심페이] ${formatPriceWon(targetItem.price)} 에스크로 결제를 요청했습니다. (상태가 '예약중'으로 전환됨)`
    );
  });

  // 3. Render Messages
  messagesEl.innerHTML = activeChat.messages
    .map(
      (m) => `
      <div class="msg-row ${m.sender}">
        <div class="msg-bubble">${m.text}</div>
        <span class="msg-time">${m.time}</span>
      </div>
    `
    )
    .join('');

  messagesEl.scrollTop = messagesEl.scrollHeight;
}

function appendChatMessage(chatId, sender, text) {
  const chat = state.chats.find((c) => c.id === chatId);
  if (!chat || !text.trim()) return;

  const now = new Date();
  const timeStr = now.toLocaleTimeString('ko-KR', { hour: 'numeric', minute: '2-digit' });

  chat.messages.push({
    id: `m-${Date.now()}`,
    sender,
    text: text.trim(),
    time: timeStr
  });
  chat.updatedAt = '방금 전';
  saveChats();
  renderChatModal();

  // Smart Contextual Seller Auto-Reply
  if (sender === 'me') {
    const item = state.items.find((i) => i.id === chat.itemId);
    setTimeout(() => {
      let reply = `네 확인했습니다! ${chat.partnerNeighborhood} 직거래 장소에서 뵙고 자세히 안내해 드릴게요 :)`;
      if (text.includes('가격 제안') || text.includes('네고')) {
        reply = `제안해 주신 금액 확인했습니다! 쿨거래 및 직접 픽업 오시면 말씀하신 조건으로 맞춰 드릴게요 👍`;
      } else if (text.includes('시승')) {
        reply = `네 좋습니다! 오늘 저녁 ${chat.partnerNeighborhood} 공영주차장 앞에서 직접 시승해 보시고 결정하세요. 헬멧/스마트키 챙겨서 나가겠습니다.`;
      } else if (text.includes('배터리') || text.includes('키로수') || text.includes('사고')) {
        reply = `실주행거리 100% 맞고 슬립이나 사고 이력 전혀 없습니다. 만나서 진단 내역도 함께 보여드릴게요!`;
      } else if (text.includes('안심페이')) {
        reply = `안심페이 확인했습니다! 매물 '예약중'으로 변경해 두었으니 직거래 시 인수 확인 버튼만 눌러주시면 됩니다.`;
      }

      chat.messages.push({
        id: `m-${Date.now()}-reply`,
        sender: 'partner',
        text: reply,
        time: new Date().toLocaleTimeString('ko-KR', { hour: 'numeric', minute: '2-digit' })
      });
      saveChats();
      renderChatModal();
    }, 850);
  }
}

// --------------------------------------------------------------------------
// Event Listeners & Initialization
// --------------------------------------------------------------------------
function bindEvents() {
  // Brand reset
  document.getElementById('brandResetLink')?.addEventListener('click', (e) => {
    e.preventDefault();
    resetAllFilters();
  });

  // Neighborhood selector
  document.getElementById('neighborhoodSelect')?.addEventListener('change', (e) => {
    state.activeNeighborhood = e.target.value;
    renderAll();
    showToast(`거래 지역이 '${state.activeNeighborhood}'(으)로 설정되었습니다.`);
  });

  // Keyboard shortcut Cmd/Ctrl + K -> focus natural language search
  window.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      document.getElementById('nlpMainInput')?.focus();
    }
  });

  // Sync Header Search & Hero Natural Language Search
  const nlpInput = document.getElementById('nlpMainInput');
  const headerSearch = document.getElementById('headerSearchInput');

  function applyNlpSearch(queryText) {
    state.nlpQuery = queryText;
    if (nlpInput && nlpInput.value !== queryText) nlpInput.value = queryText;
    if (headerSearch && headerSearch.value !== queryText) headerSearch.value = queryText;
    state.parsedNlp = parseNaturalLanguageQuery(queryText);
    renderAll();
  }

  document.getElementById('nlpSearchForm')?.addEventListener('submit', (e) => {
    e.preventDefault();
    applyNlpSearch(nlpInput?.value || '');
  });

  nlpInput?.addEventListener('input', (e) => {
    applyNlpSearch(e.target.value);
  });

  headerSearch?.addEventListener('input', (e) => {
    applyNlpSearch(e.target.value);
  });

  document.getElementById('nlpClearBtn')?.addEventListener('click', () => {
    applyNlpSearch('');
  });

  document.getElementById('nlpResetBtn')?.addEventListener('click', () => {
    resetAllFilters();
  });

  // NLP Suggestion Chips click delegation
  document.getElementById('nlpChipsRow')?.addEventListener('click', (e) => {
    const chip = e.target.closest('[data-nlp-query]');
    if (!chip) return;
    applyNlpSearch(chip.dataset.nlpQuery);
  });

  // Category Dock delegation
  document.getElementById('categoryDock')?.addEventListener('click', (e) => {
    const card = e.target.closest('[data-category-id]');
    if (!card) return;
    state.activeCategory = card.dataset.categoryId;
    state.onlyLiked = false;
    renderAll();
  });

  // Filter checkboxes & Sort & View toggle
  document.getElementById('filterAvailableOnly')?.addEventListener('change', (e) => {
    state.onlyAvailable = e.target.checked;
    renderItems();
  });

  document.getElementById('filterTestRideOnly')?.addEventListener('change', (e) => {
    state.onlyTestRide = e.target.checked;
    renderItems();
  });

  document.getElementById('filterNegotiableOnly')?.addEventListener('change', (e) => {
    state.onlyNegotiable = e.target.checked;
    renderItems();
  });

  document.getElementById('sortSelect')?.addEventListener('change', (e) => {
    state.sortBy = e.target.value;
    renderItems();
  });

  document.getElementById('viewGridBtn')?.addEventListener('click', () => {
    state.viewMode = 'grid';
    document.getElementById('viewGridBtn')?.classList.add('active');
    document.getElementById('viewListBtn')?.classList.remove('active');
    renderItems();
  });

  document.getElementById('viewListBtn')?.addEventListener('click', () => {
    state.viewMode = 'list';
    document.getElementById('viewListBtn')?.classList.add('active');
    document.getElementById('viewGridBtn')?.classList.remove('active');
    renderItems();
  });

  // Header Wishlist Filter toggle
  document.getElementById('wishlistFilterBtn')?.addEventListener('click', () => {
    state.onlyLiked = !state.onlyLiked;
    renderAll();
    if (state.onlyLiked) {
      showToast('내가 찜한 모빌리티 모아보기 화면입니다.');
    }
  });

  // Item Card click delegation (Open Detail vs Toggle Heart)
  document.getElementById('itemsContainer')?.addEventListener('click', (e) => {
    const likeBtn = e.target.closest('[data-like-id]');
    if (likeBtn) {
      e.stopPropagation();
      toggleLikeItem(likeBtn.dataset.likeId);
      return;
    }

    const card = e.target.closest('[data-item-id]');
    if (card) {
      openDetailModal(card.dataset.itemId);
    }
  });

  // Close Dialog buttons
  document.querySelectorAll('[data-close-dialog]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const dialogId = btn.dataset.closeDialog;
      document.getElementById(dialogId)?.close();
    });
  });

  // Open Register Modal
  document.getElementById('openRegisterModalBtn')?.addEventListener('click', () => {
    if (state.regPhotos.length === 0) {
      const defaultCat = document.getElementById('regCategory')?.value || 'cycle';
      state.regPhotos = [PRESET_PHOTOS[defaultCat][0]];
      renderRegisterPhotoPreviews();
    }
    document.getElementById('registerDialog')?.showModal();
  });

  // Register Form interactions
  document.getElementById('addPresetPhotoBtn')?.addEventListener('click', addPresetPhotosForCurrentCategory);
  document.getElementById('aiDraftDescBtn')?.addEventListener('click', generateAiMobilityDescription);

  document.getElementById('photoFileInput')?.addEventListener('change', (e) => {
    const files = Array.from(e.target.files || []);
    files.forEach((file) => {
      if (state.regPhotos.length >= 5) return;
      const reader = new FileReader();
      reader.onload = (ev) => {
        if (state.regPhotos.length < 5) {
          state.regPhotos.push(ev.target.result);
          renderRegisterPhotoPreviews();
        }
      };
      reader.readAsDataURL(file);
    });
  });

  document.getElementById('regPrice')?.addEventListener('input', (e) => {
    const helper = document.getElementById('koreanPricePreview');
    if (helper) helper.textContent = formatKoreanCurrencyHelper(e.target.value);
  });

  document.getElementById('registerForm')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const cat = document.getElementById('regCategory').value;
    const neighborhood = document.getElementById('regNeighborhood').value;
    const title = document.getElementById('regTitle').value.trim();
    const price = Number(document.getElementById('regPrice').value) || 0;
    const negotiable = document.getElementById('regNegotiable').checked;
    const year = Number(document.getElementById('regYear').value) || 2025;
    const mileageRaw = document.getElementById('regMileage').value;
    const batteryRaw = document.getElementById('regBattery').value;
    const condition = document.getElementById('regCondition').value;
    const testRideAvailable = document.getElementById('regTestRide').value === 'true';
    const rawTags = document.getElementById('regTags').value;
    const description = document.getElementById('regDesc').value.trim();

    const images =
      state.regPhotos.length > 0
        ? [...state.regPhotos]
        : [PRESET_PHOTOS[cat]?.[0] || PRESET_PHOTOS['cycle'][0]];

    const tags = rawTags
      .split(',')
      .map((t) => t.trim().replace(/^#/, ''))
      .filter(Boolean);

    const newItem = {
      id: `movo-${Date.now()}`,
      title,
      category: cat,
      price,
      marketPriceMin: Math.round(price * 0.93),
      marketPriceMax: Math.round(price * 1.08),
      negotiable,
      status: 'selling',
      condition,
      year,
      mileageKm: mileageRaw !== '' ? Number(mileageRaw) : null,
      batteryHealth: batteryRaw !== '' ? Number(batteryRaw) : null,
      testRideAvailable,
      neighborhood,
      distanceKm: 0.4,
      timeAgo: '방금 전',
      createdAt: Date.now(),
      likes: 1,
      chats: 0,
      views: 1,
      isLiked: false,
      images,
      tags: tags.length > 0 ? tags : [getCategoryObj(cat).shortName, condition, neighborhood],
      description,
      seller: {
        name: '나의모빌리티',
        avatar: '✨',
        mannerTemp: 42.5,
        verifiedLocation: `${neighborhood} 동네인증 완료`,
        responseRate: '100% (보통 1분 내 응답)',
        tradesCount: 8
      }
    };

    state.items.unshift(newItem);
    saveItems();

    // Reset form & close modal
    e.target.reset();
    state.regPhotos = [];
    renderRegisterPhotoPreviews();
    document.getElementById('registerDialog')?.close();

    state.activeCategory = 'all';
    renderAll();
    showToast(`🎉 '${newItem.title}' 매물이 성공적으로 등록되었습니다!`);
  });

  // Offer / Price Edit Form submit
  document.querySelectorAll('#offerForm [data-discount]').forEach((chip) => {
    chip.addEventListener('click', () => {
      const item = state.items.find((i) => i.id === state.activeDetailItemId);
      if (!item) return;
      const ratio = Number(chip.dataset.discount);
      const discounted = Math.round((item.price * ratio) / 1000) * 1000;
      document.getElementById('offerPriceInput').value = discounted;
    });
  });

  document.getElementById('offerForm')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const item = state.items.find((i) => i.id === state.activeDetailItemId);
    if (!item) return;
    const newPrice = Number(document.getElementById('offerPriceInput').value);

    document.getElementById('offerDialog')?.close();

    if (currentOfferMode === 'edit') {
      item.price = newPrice;
      saveItems();
      renderItems();
      renderDetailModalContent(item);
      showToast(`판매가격이 ${formatPriceWon(newPrice)}(으)로 수정되었습니다.`);
    } else {
      document.getElementById('detailDialog')?.close();
      openChatForItem(
        item,
        `[가격 제안] 안녕하세요! '${item.title}' 매물을 ${formatPriceWon(newPrice)}에 쿨거래 희망합니다. 가능할까요?`
      );
      showToast('판매자에게 가격 제안 메시지를 전송했습니다.');
    }
  });

  // Open Chat Modal from header
  document.getElementById('openChatModalBtn')?.addEventListener('click', () => {
    renderChatModal();
    document.getElementById('chatDialog')?.showModal();
  });

  // Chat Quick Chips
  document.getElementById('chatQuickChips')?.addEventListener('click', (e) => {
    const chip = e.target.closest('[data-msg]');
    if (!chip || !state.activeChatId) return;
    appendChatMessage(state.activeChatId, 'me', chip.dataset.msg);
  });

  // Chat Send Form
  document.getElementById('chatSendForm')?.addEventListener('submit', (e) => {
    e.preventDefault();
    const input = document.getElementById('chatTextInput');
    if (!input || !input.value.trim() || !state.activeChatId) return;
    appendChatMessage(state.activeChatId, 'me', input.value);
    input.value = '';
  });
}

// Initialize App
document.addEventListener('DOMContentLoaded', () => {
  loadState();
  renderNlpSuggestionChips();
  bindEvents();
  renderAll();
});
