/**
 * Tô Na Rota — Landing Page Application Logic
 * Unified drill-down navigation: Balneários → Estabelecimentos
 */

const API_BASE = '/api/v1';

// ─── State ─────────────────────────────────────────────────────────
let allBalnearios = [];
let allCategorias = [];
let allEstabelecimentos = [];
let selectedBalneario = null;   // null = showing balneário cards
let selectedCategory = 'Todos';
let searchQuery = '';

// ─── DOM Refs ──────────────────────────────────────────────────────
const grid = document.getElementById('card-grid');
const searchInput = document.getElementById('search-input');
const chipContainer = document.getElementById('filter-chips');
const breadcrumb = document.getElementById('breadcrumb');
const breadcrumbCurrent = document.getElementById('breadcrumb-current');
const btnBack = document.getElementById('btn-back');
const sectionTitle = document.getElementById('section-title');
const sectionSubtitle = document.getElementById('section-subtitle');
const statBalnearios = document.getElementById('stat-balnearios');
const statCategorias = document.getElementById('stat-categorias');
const statEstabelecimentos = document.getElementById('stat-estabelecimentos');

// ─── API Helpers ───────────────────────────────────────────────────
async function apiFetch(endpoint) {
  try {
    const res = await fetch(`${API_BASE}${endpoint}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.warn(`[API] Falha ao buscar ${endpoint}:`, err.message);
    return null;
  }
}

// ─── Utilities ─────────────────────────────────────────────────────
function renderSkeletons(count = 6) {
  grid.innerHTML = Array.from({ length: count }, () =>
    `<div class="skeleton skeleton-card"></div>`
  ).join('');
}

function escapeHtml(str) {
  const el = document.createElement('span');
  el.textContent = str;
  return el.innerHTML;
}

const ICON_MAP = {
  'beach_access': '🏖️', 'waterfall_chart': '💧', 'hot_tub': '♨️',
  'pool': '🏊', 'landscape': '⛰️', 'forest': '🌲', 'park': '🌳',
  'waves': '🌊', 'heart': '❤️', 'star': '⭐', 'explore': '🧭',
  'place': '📍', 'restaurant': '🍽️', 'hotel': '🏨',
  'directions_boat': '🚤', 'shopping_bag': '🛍️',
};

function getIconForCategory(iconName) {
  return ICON_MAP[iconName] || '📍';
}

function animateNumber(el, target) {
  let current = 0;
  const step = Math.max(1, Math.ceil(target / 30));
  const interval = setInterval(() => {
    current = Math.min(current + step, target);
    el.textContent = current;
    if (current >= target) clearInterval(interval);
  }, 30);
}

// ─── Navigation ────────────────────────────────────────────────────
function navigateToBalnearios() {
  selectedBalneario = null;
  selectedCategory = 'Todos';
  searchInput.value = '';
  searchQuery = '';

  breadcrumb.style.display = 'none';
  chipContainer.style.display = 'none';
  sectionTitle.textContent = 'Destinos em destaque';
  sectionSubtitle.textContent = 'Explore os balneários cadastrados na plataforma.';
  searchInput.placeholder = 'Buscar praias, cachoeiras, comodidades...';

  renderView();
}

function navigateToEstabelecimentos(balnearioId) {
  const bal = allBalnearios.find(b => b.id === balnearioId);
  if (!bal) return;

  selectedBalneario = bal;
  selectedCategory = 'Todos';
  searchInput.value = '';
  searchQuery = '';

  breadcrumb.style.display = 'flex';
  breadcrumbCurrent.textContent = bal.nome;
  chipContainer.style.display = 'flex';
  sectionTitle.textContent = `Estabelecimentos em ${bal.nome}`;

  const estCount = allEstabelecimentos.filter(
    e => e.balneario_id === bal.id && e.status === 'ativo'
  ).length;
  sectionSubtitle.textContent = `${estCount} estabelecimento${estCount !== 1 ? 's' : ''} cadastrado${estCount !== 1 ? 's' : ''} neste destino.`;
  searchInput.placeholder = `Buscar em ${bal.nome}...`;

  // Scroll to top of main content smoothly
  document.getElementById('main-content').scrollIntoView({ behavior: 'smooth', block: 'start' });

  renderChips();
  renderView();
}

// ─── Unified Render ────────────────────────────────────────────────
function renderView() {
  if (selectedBalneario) {
    renderEstabelecimentoCards();
  } else {
    renderBalnearioCards();
  }
}

// ─── Balneário Cards ───────────────────────────────────────────────
function renderBalnearioCards() {
  const q = searchQuery.toLowerCase();
  const filtered = allBalnearios.filter(b => {
    if (!q) return true;
    return (b.nome || '').toLowerCase().includes(q) ||
      (b.descricao || '').toLowerCase().includes(q) ||
      (b.municipio || '').toLowerCase().includes(q);
  });

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <div class="icon">🔍</div>
        <h3>Nenhum destino encontrado</h3>
        <p>Tente redefinir sua busca.</p>
      </div>`;
    return;
  }

  grid.innerHTML = filtered.map(b => {
    const imgUrl = b.imagem_capa_url || '';
    const hasImage = imgUrl && (imgUrl.startsWith('http') || imgUrl.startsWith('/'));
    const imageSrc = hasImage
      ? imgUrl
      : `https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80`;

    const municipio = escapeHtml(b.municipio || '');
    const estado = escapeHtml(b.estado || '');
    const descricao = escapeHtml(b.descricao || 'Descubra este destino incrível.');

    // Count active establishments in this balneário
    const estCount = allEstabelecimentos.filter(
      e => e.balneario_id === b.id && e.status === 'ativo'
    ).length;

    return `
      <article class="card" data-balneario-id="${b.id}" role="button" tabindex="0">
        <div class="card-image-wrapper">
          <img class="card-image"
               src="${imageSrc}"
               alt="${escapeHtml(b.nome)}"
               loading="lazy"
               onerror="this.src='https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'" />
          ${estCount > 0 ? `<span class="card-badge">🏪 ${estCount} estabelecimento${estCount !== 1 ? 's' : ''}</span>` : ''}
        </div>
        <div class="card-body">
          <div class="card-header">
            <h3 class="card-title">${escapeHtml(b.nome)}</h3>
          </div>
          ${municipio ? `<div class="card-location">📍 ${municipio}${estado ? ' — ' + estado : ''}</div>` : ''}
          <p class="card-desc">${descricao}</p>
          <div class="card-footer">
            <div class="card-tags">
              ${estCount > 0 ? `<span class="tag">Clique para explorar</span>` : `<span class="tag" style="opacity:0.5">Sem estabelecimentos</span>`}
            </div>
          </div>
        </div>
      </article>`;
  }).join('');

  // Bind click on balneário cards
  grid.querySelectorAll('.card[data-balneario-id]').forEach(card => {
    const handler = () => navigateToEstabelecimentos(card.dataset.balnearioId);
    card.addEventListener('click', handler);
    card.addEventListener('keydown', e => { if (e.key === 'Enter') handler(); });
  });
}

// ─── Estabelecimento Cards ─────────────────────────────────────────
function renderEstabelecimentoCards() {
  if (!selectedBalneario) return;

  const q = searchQuery.toLowerCase();
  const filtered = allEstabelecimentos.filter(e => {
    if (e.status !== 'ativo') return false;
    if (e.balneario_id !== selectedBalneario.id) return false;
    const matchesCat = selectedCategory === 'Todos' || e._categoriaNome === selectedCategory;
    const matchesSearch = !q ||
      (e.nome_fantasia || '').toLowerCase().includes(q) ||
      (e.descricao || '').toLowerCase().includes(q) ||
      (e._categoriaNome || '').toLowerCase().includes(q);
    return matchesCat && matchesSearch;
  });

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <div class="icon">🏪</div>
        <h3>Nenhum estabelecimento encontrado</h3>
        <p>${searchQuery || selectedCategory !== 'Todos'
          ? 'Tente redefinir sua busca ou alterar a categoria.'
          : 'Este destino ainda não possui estabelecimentos cadastrados.'}</p>
        <button class="btn btn-outline" style="margin-top:16px" onclick="navigateToBalnearios()">← Voltar aos destinos</button>
      </div>`;
    return;
  }

  grid.innerHTML = filtered.map(e => {
    const logoUrl = e.logomarca_url || '';
    const hasLogo = logoUrl && (logoUrl.startsWith('http') || logoUrl.startsWith('/'));
    const logoSrc = hasLogo
      ? logoUrl
      : `https://ui-avatars.com/api/?name=${encodeURIComponent(e.nome_fantasia || 'E')}&background=0D9488&color=fff&size=112&font-size=0.4`;

    const categoriaNome = escapeHtml(e._categoriaNome || 'Negócio');
    const categoriaIcon = e._categoriaIcone ? getIconForCategory(e._categoriaIcone) : '🏪';

    const nota = (typeof e.nota_media === 'number') ? e.nota_media.toFixed(1) : '0.0';
    const totalAval = e.total_avaliacoes || 0;

    // Generate visual stars
    const notaNum = parseFloat(nota);
    const fullStars = Math.floor(notaNum);
    const halfStar = (notaNum - fullStars) >= 0.3;
    let starsHtml = '';
    for (let i = 0; i < fullStars; i++) starsHtml += '★';
    if (halfStar) starsHtml += '½';
    if (!starsHtml) starsHtml = '☆';

    const descricao = escapeHtml(e.descricao || '');
    const endereco = escapeHtml(e.endereco || '');
    const plano = e.plano || 'gratuito';
    const planoLabel = plano === 'premium' ? '⭐ Premium' : 'Gratuito';

    // Contact links
    const whatsapp = e.whatsapp || '';
    const whatsappHref = whatsapp ? `https://wa.me/${whatsapp.replace(/\D/g, '')}` : '';
    const instagram = e.instagram || '';
    const instagramHref = instagram ? `https://instagram.com/${instagram.replace('@', '')}` : '';

    return `
      <article class="est-card" data-id="${e.id}">
        <div class="est-card-header">
          <img class="est-card-logo"
               src="${logoSrc}"
               alt="${escapeHtml(e.nome_fantasia)}"
               loading="lazy"
               onerror="this.src='https://ui-avatars.com/api/?name=${encodeURIComponent(e.nome_fantasia || 'E')}&background=0D9488&color=fff&size=112&font-size=0.4'" />
          <div class="est-card-info">
            <div class="est-card-name">${escapeHtml(e.nome_fantasia)}</div>
            <div class="est-card-category">${categoriaIcon} ${categoriaNome}</div>
          </div>
          ${totalAval > 0 ? `
          <div class="est-card-rating">
            <span class="stars">${starsHtml} ${nota}</span>
            <span class="count">(${totalAval})</span>
          </div>` : ''}
        </div>
        <div class="est-card-body">
          <p class="est-card-desc">${descricao}</p>
          ${endereco ? `<div class="est-card-location">📍 ${endereco}</div>` : ''}
        </div>
        <div class="est-card-footer">
          <span class="plan-badge ${plano}">${planoLabel}</span>
          <div class="contact-links">
            ${whatsappHref ? `<a href="${whatsappHref}" target="_blank" rel="noopener" class="contact-link whatsapp" title="WhatsApp">📱</a>` : ''}
            ${instagramHref ? `<a href="${instagramHref}" target="_blank" rel="noopener" class="contact-link instagram" title="Instagram">📷</a>` : ''}
          </div>
        </div>
      </article>`;
  }).join('');
}

// ─── Category Chips ────────────────────────────────────────────────
function renderChips() {
  // Only show chips that have establishments in this balneário
  const relevantCatIds = new Set(
    allEstabelecimentos
      .filter(e => e.balneario_id === selectedBalneario?.id && e.status === 'ativo')
      .map(e => e.categoria_id)
  );

  const categoriaEntries = [
    { nome: 'Todos', icone: null },
    ...allCategorias
      .filter(c => relevantCatIds.has(c.id))
      .map(c => ({ nome: c.nome, icone: c.icone }))
  ];

  chipContainer.innerHTML = categoriaEntries.map(entry => {
    const isActive = selectedCategory === entry.nome ? 'active' : '';
    const icon = entry.icone ? getIconForCategory(entry.icone) : (entry.nome === 'Todos' ? '✓' : '');
    return `<button class="chip ${isActive}" data-category="${escapeHtml(entry.nome)}">${icon ? icon + ' ' : ''}${escapeHtml(entry.nome)}</button>`;
  }).join('');

  chipContainer.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      selectedCategory = chip.dataset.category;
      renderChips();
      renderView();
    });
  });
}

// ─── Stats ─────────────────────────────────────────────────────────
function updateStats(animate) {
  const activeEsts = allEstabelecimentos.filter(e => e.status === 'ativo').length;
  if (animate) {
    if (statBalnearios) animateNumber(statBalnearios, allBalnearios.length);
    if (statCategorias) animateNumber(statCategorias, allCategorias.length);
    if (statEstabelecimentos) animateNumber(statEstabelecimentos, activeEsts);
  } else {
    if (statBalnearios) statBalnearios.textContent = allBalnearios.length;
    if (statCategorias) statCategorias.textContent = allCategorias.length;
    if (statEstabelecimentos) statEstabelecimentos.textContent = activeEsts;
  }
}

// ─── Category Inference for Balneários ─────────────────────────────
function inferCategory(balneario, categorias) {
  const textoBusca = `${balneario.nome} ${balneario.descricao || ''}`.toLowerCase();
  for (const cat of categorias) {
    const catNome = cat.nome.toLowerCase();
    if (textoBusca.includes(catNome)) return cat;
    if (catNome.endsWith('s') && textoBusca.includes(catNome.slice(0, -1))) return cat;
  }
  const keywords = {
    'praia': 'Praias', 'mar': 'Praias', 'surf': 'Praias', 'areia': 'Praias',
    'cachoeira': 'Cachoeiras', 'queda': 'Cachoeiras',
    'terma': 'Termas', 'thermal': 'Termas',
    'lagoa': 'Lagoas', 'lago': 'Lagoas',
  };
  for (const [keyword, catNome] of Object.entries(keywords)) {
    if (textoBusca.includes(keyword)) {
      return categorias.find(c => c.nome === catNome) || null;
    }
  }
  return null;
}

// ─── Search ────────────────────────────────────────────────────────
function setupSearch() {
  let debounceTimer;
  searchInput.addEventListener('input', (e) => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      searchQuery = e.target.value.trim();
      renderView();
    }, 200);
  });
}

// ─── Bootstrap ─────────────────────────────────────────────────────
async function fetchDataAndRender(showSkeletons = false) {
  if (showSkeletons) renderSkeletons();

  const [categorias, balnearios, estabelecimentos] = await Promise.all([
    apiFetch('/categorias?ativos=true'),
    apiFetch('/balnearios?ativos=true'),
    apiFetch('/estabelecimentos'),
  ]);

  if (!categorias && !balnearios && !estabelecimentos) return;

  allCategorias = categorias || [];

  allBalnearios = (balnearios || []).map(b => {
    let cat = b.categoria_id ? allCategorias.find(c => c.id === b.categoria_id) : null;
    if (!cat) cat = inferCategory(b, allCategorias);
    return { ...b, _categoriaNome: cat?.nome || 'Destino', _categoriaIcone: cat?.icone || null };
  });

  allEstabelecimentos = (estabelecimentos || []).map(e => {
    const cat = allCategorias.find(c => c.id === e.categoria_id);
    return {
      ...e,
      _categoriaNome: cat?.nome || 'Negócio',
      _categoriaIcone: cat?.icone || null,
    };
  });

  updateStats(showSkeletons);

  // Re-render current view (preserves drill-down state)
  if (selectedBalneario) {
    renderChips();
  }
  renderView();
}

async function init() {
  // Bind back button
  btnBack.addEventListener('click', navigateToBalnearios);

  await fetchDataAndRender(true);
  setupSearch();
}

document.addEventListener('DOMContentLoaded', init);
