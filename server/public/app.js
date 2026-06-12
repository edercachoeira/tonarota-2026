/**
 * Tô Na Rota — Landing Page Application Logic
 * Fetches real data from the Dart Shelf API and renders it dynamically.
 */

const API_BASE = '/api/v1';

// ─── State ─────────────────────────────────────────────────────────
let allBalnearios = [];
let allCategorias = [];
let selectedCategory = 'Todos';
let searchQuery = '';

// ─── DOM Refs ──────────────────────────────────────────────────────
const grid = document.getElementById('card-grid');
const searchInput = document.getElementById('search-input');
const chipContainer = document.getElementById('filter-chips');
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

// ─── Render Functions ──────────────────────────────────────────────
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

// Ícones Material Design mapeados para emoji/unicode equivalente
const ICON_MAP = {
  'beach_access': '🏖️',
  'waterfall_chart': '💧',
  'hot_tub': '♨️',
  'pool': '🏊',
  'landscape': '⛰️',
  'forest': '🌲',
  'park': '🌳',
  'waves': '🌊',
  'heart': '❤️',
  'star': '⭐',
  'explore': '🧭',
  'place': '📍',
};

function getIconForCategory(iconName) {
  return ICON_MAP[iconName] || '📍';
}

function renderCards() {
  const filtered = allBalnearios.filter(b => {
    const matchesCat = selectedCategory === 'Todos' || b._categoriaNome === selectedCategory;
    const q = searchQuery.toLowerCase();
    const matchesSearch = !q ||
      (b.nome || '').toLowerCase().includes(q) ||
      (b.descricao || '').toLowerCase().includes(q) ||
      (b.municipio || '').toLowerCase().includes(q) ||
      (b._categoriaNome || '').toLowerCase().includes(q);
    return matchesCat && matchesSearch;
  });

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="empty-state">
        <div class="icon">🔍</div>
        <h3>Nenhum destino encontrado</h3>
        <p>Tente redefinir sua busca ou alterar a categoria selecionada.</p>
      </div>`;
    return;
  }

  grid.innerHTML = filtered.map(b => {
    const imgUrl = b.imagem_capa_url || '';
    // Aceitar URLs absolutas (http/https) e URLs relativas do servidor (/uploads/...)
    const hasImage = imgUrl && (imgUrl.startsWith('http') || imgUrl.startsWith('/'));
    const imageSrc = hasImage
      ? imgUrl
      : `https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80`;

    const categoriaNome = escapeHtml(b._categoriaNome || 'Destino');
    const categoriaIcon = b._categoriaIcone ? getIconForCategory(b._categoriaIcone) : '📍';
    const municipio = escapeHtml(b.municipio || '');
    const estado = escapeHtml(b.estado || '');
    const descricao = escapeHtml(b.descricao || 'Descubra este destino incrível.');

    // Formata a data de última atualização
    const updatedAt = b.updated_at ? new Date(b.updated_at) : null;
    const dateStr = updatedAt ? updatedAt.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' }) : '';

    return `
      <article class="card" data-id="${b.id}">
        <div class="card-image-wrapper">
          <img class="card-image" 
               src="${imageSrc}" 
               alt="${escapeHtml(b.nome)}"
               loading="lazy"
               onerror="this.src='https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'" />
          <span class="card-badge">${categoriaIcon} ${categoriaNome}</span>
        </div>
        <div class="card-body">
          <div class="card-header">
            <h3 class="card-title">${escapeHtml(b.nome)}</h3>
          </div>
          ${municipio ? `<div class="card-location">📍 ${municipio}${estado ? ' — ' + estado : ''}</div>` : ''}
          <p class="card-desc">${descricao}</p>
          <div class="card-footer">
            <div class="card-tags">
              <span class="tag">${categoriaNome}</span>
            </div>
            ${dateStr ? `<span class="card-date">${dateStr}</span>` : ''}
          </div>
        </div>
      </article>`;
  }).join('');
}

function renderChips() {
  const categoriaEntries = [
    { nome: 'Todos', icone: null },
    ...allCategorias.map(c => ({ nome: c.nome, icone: c.icone }))
  ];

  chipContainer.innerHTML = categoriaEntries.map(entry => {
    const isActive = selectedCategory === entry.nome ? 'active' : '';
    const icon = entry.icone ? getIconForCategory(entry.icone) : (entry.nome === 'Todos' ? '✓' : '');
    return `<button class="chip ${isActive}" data-category="${escapeHtml(entry.nome)}">${icon ? icon + ' ' : ''}${escapeHtml(entry.nome)}</button>`;
  }).join('');

  // Bind click handlers
  chipContainer.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      selectedCategory = chip.dataset.category;
      renderChips();
      renderCards();
    });
  });
}

function updateStats() {
  if (statBalnearios) {
    animateNumber(statBalnearios, allBalnearios.length);
  }
  if (statCategorias) {
    animateNumber(statCategorias, allCategorias.length);
  }
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

// ─── Inferir categoria do balneário ────────────────────────────────
// Como o modelo Balneário não tem um campo categoria_id direto,
// tentamos inferir a categoria a partir do nome/descrição do balneário
// comparando com os nomes das categorias existentes.
function inferCategory(balneario, categorias) {
  const textoBusca = `${balneario.nome} ${balneario.descricao || ''}`.toLowerCase();
  
  for (const cat of categorias) {
    const catNome = cat.nome.toLowerCase();
    // Verifica se o nome da categoria (singular ou plural) aparece no texto
    if (textoBusca.includes(catNome)) {
      return cat;
    }
    // Tenta o singular (remove 's' final)
    if (catNome.endsWith('s') && textoBusca.includes(catNome.slice(0, -1))) {
      return cat;
    }
  }
  
  // Mapeamentos conhecidos por palavras-chave
  const keywords = {
    'praia': 'Praias',
    'mar': 'Praias',
    'surf': 'Praias',
    'areia': 'Praias',
    'oceân': 'Praias',
    'cachoeira': 'Cachoeiras',
    'queda': 'Cachoeiras',
    'trilha': 'Cachoeiras',
    'terma': 'Termas',
    'thermal': 'Termas',
    'aquecid': 'Termas',
    'lagoa': 'Lagoas',
    'lago': 'Lagoas',
  };
  
  for (const [keyword, catNome] of Object.entries(keywords)) {
    if (textoBusca.includes(keyword)) {
      return categorias.find(c => c.nome === catNome) || null;
    }
  }
  
  return null;
}

// ─── Event Handlers ────────────────────────────────────────────────
function setupSearch() {
  let debounceTimer;
  searchInput.addEventListener('input', (e) => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      searchQuery = e.target.value.trim();
      renderCards();
    }, 200);
  });
}

// ─── Bootstrap ─────────────────────────────────────────────────────
// ─── Bootstrap ─────────────────────────────────────────────────────
async function fetchDataAndRender(showSkeletons = false) {
  if (showSkeletons) {
    renderSkeletons();
  }

  // Fetch data in parallel
  const [categorias, balnearios, estabelecimentos] = await Promise.all([
    apiFetch('/categorias?ativos=true'),
    apiFetch('/balnearios?ativos=true'),
    apiFetch('/estabelecimentos'),
  ]);

  if (!categorias && !balnearios) return;

  // Populate state
  allCategorias = categorias || [];
  allBalnearios = (balnearios || []).map(b => {
    let cat = null;
    if (b.categoria_id) {
      cat = allCategorias.find(c => c.id === b.categoria_id);
    }
    if (!cat) {
      cat = inferCategory(b, allCategorias);
    }
    return {
      ...b,
      _categoriaNome: cat ? cat.nome : 'Destino',
      _categoriaIcone: cat ? cat.icone : null,
    };
  });

  // Update stats
  if (showSkeletons) {
    updateStats();
    if (statEstabelecimentos && estabelecimentos) {
      animateNumber(statEstabelecimentos, estabelecimentos.length);
    }
  } else {
    // Silent update sem animações
    if (statBalnearios) statBalnearios.textContent = allBalnearios.length;
    if (statCategorias) statCategorias.textContent = allCategorias.length;
    if (statEstabelecimentos && estabelecimentos) {
      statEstabelecimentos.textContent = estabelecimentos.length;
    }
  }

  // Render UI
  renderChips();
  renderCards();
}

async function init() {
  await fetchDataAndRender(true);
  setupSearch();

  // Polling em tempo real a cada 5 segundos
  setInterval(() => {
    fetchDataAndRender(false);
  }, 5000);
}

document.addEventListener('DOMContentLoaded', init);
