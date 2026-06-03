// ==========================================================================
// ROYAL SHETKARI ADMIN CENTER - JAVASCRIPT APPLICATION
// ==========================================================================

const API_BASE = '/api/v1';

// Global Application State
const state = {
  token: localStorage.getItem('admin_token'),
  adminUser: null,
  shops: [],
  claims: [],
  activeTab: 'dashboard',
  sseSource: null,
  // Temporal holds for modal editing
  editingShopId: null,
  existingImages: [], // holds paths of images currently in shop profile
  newProfileFile: null,
  newGalleryFiles: []
};

// CSS category mappings for Marathi & English names
const CATEGORIES = {
  fertilizers: { mr: 'खते व बियाणे', en: 'Fertilizers & Seeds' },
  crop: { mr: 'धान्य व पीक बाजार', en: 'Crop Market' },
  equipment_repair: { mr: 'शेती अवजारे दुरुस्ती', en: 'Equipment Repairing' },
  hardware: { mr: 'कृषी हार्डवेअर', en: 'Hardware Shop' },
  organic_farming: { mr: 'सेंद्रिय शेती साहित्य', en: 'Organic Farming' },
  animal_doctor: { mr: 'पशुवैद्यकीय डॉक्टर', en: 'Animal Doctor / Vet' },
  produce_buyer: { mr: 'शेतमाल खरेदीदार', en: 'Agricultural Produce Buyer' },
  medical: { mr: 'वैद्यकीय सेवा', en: 'Medical Shop / Services' }
};

// Document Elements
const el = {
  loginScreen: document.getElementById('login-screen'),
  loginForm: document.getElementById('login-form'),
  loginMobile: document.getElementById('login-mobile'),
  loginPassword: document.getElementById('login-password'),
  loginError: document.getElementById('login-error'),
  
  adminPanel: document.getElementById('admin-panel'),
  adminName: document.getElementById('admin-name'),
  logoutBtn: document.getElementById('logout-btn'),
  navItems: document.querySelectorAll('.nav-item'),
  tabPanes: document.querySelectorAll('.tab-pane'),
  toastContainer: document.getElementById('toast-container'),
  statusDot: document.getElementById('status-dot'),
  statusText: document.getElementById('status-text'),
  
  // Dashboard Overview
  statTotalShops: document.getElementById('stat-total-shops'),
  statActiveShops: document.getElementById('stat-active-shops'),
  statTotalClaims: document.getElementById('stat-total-claims'),
  liveClaimStream: document.getElementById('live-claim-stream'),
  categoryMetricsList: document.getElementById('category-metrics-list'),
  
  // Shop Management Tab
  shopSearch: document.getElementById('shop-search'),
  filterCategory: document.getElementById('filter-category'),
  shopsCountBadge: document.getElementById('shops-count-badge'),
  shopRegistryRows: document.getElementById('shop-registry-rows'),
  
  // Coin Claims Tab
  claimsSearch: document.getElementById('claims-search'),
  claimsLogRows: document.getElementById('claims-log-rows'),
  
  // Edit Modal
  editShopModal: document.getElementById('edit-shop-modal'),
  editShopForm: document.getElementById('edit-shop-form'),
  modalCloseBtn: document.getElementById('modal-close-btn'),
  modalCancelBtn: document.getElementById('modal-cancel-btn'),
  editShopId: document.getElementById('edit-shop-id'),
  editShopName: document.getElementById('edit-shop-name'),
  editOwnerName: document.getElementById('edit-owner-name'),
  editCity: document.getElementById('edit-city'),
  editPincode: document.getElementById('edit-pincode'),
  editAddress: document.getElementById('edit-address'),
  editMobile: document.getElementById('edit-mobile'),
  editWhatsapp: document.getElementById('edit-whatsapp'),
  editServices: document.getElementById('edit-services'),
  editCoinsRequired: document.getElementById('edit-coins-required'),
  editDiscountPercentage: document.getElementById('edit-discount-percentage'),
  editProfilePreview: document.getElementById('edit-profile-preview'),
  editProfileInput: document.getElementById('edit-profile-input'),
  editGalleryInput: document.getElementById('edit-gallery-input'),
  galleryPreviewsContainer: document.getElementById('gallery-previews-container'),
  btnDeleteProfilePhoto: document.getElementById('btn-delete-profile-photo')
};

// Initial Start
document.addEventListener('DOMContentLoaded', () => {
  setupEventListeners();
  if (state.token) {
    initializeDashboard();
  } else {
    showLogin();
  }
});

// Setup Listeners
function setupEventListeners() {
  // Login Form
  el.loginForm.addEventListener('submit', handleLogin);
  
  // Logout
  el.logoutBtn.addEventListener('click', handleLogout);
  
  // Tab Navigation
  el.navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = item.getAttribute('data-tab');
      switchTab(tabId);
    });
  });
  
  // Shop Searching and Filtering
  el.shopSearch.addEventListener('input', renderShopsTable);
  el.filterCategory.addEventListener('change', renderShopsTable);
  
  // Claims Searching
  el.claimsSearch.addEventListener('input', renderClaimsTable);
  
  // Modal Closes
  el.modalCloseBtn.addEventListener('click', closeEditModal);
  el.modalCancelBtn.addEventListener('click', closeEditModal);
  
  // Profile Image Selection Preview
  el.editProfileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      state.newProfileFile = file;
      el.editProfilePreview.src = URL.createObjectURL(file);
    }
  });

  // Delete profile photo click
  el.btnDeleteProfilePhoto.addEventListener('click', () => {
    state.newProfileFile = null;
    el.editProfilePreview.src = '';
    el.editProfileInput.value = '';
  });

  // Gallery Image Selection Add
  el.editGalleryInput.addEventListener('change', (e) => {
    const files = Array.from(e.target.files);
    files.forEach(file => {
      state.newGalleryFiles.push(file);
      renderGalleryGrid();
    });
  });

  // Edit Shop Submit
  el.editShopForm.addEventListener('submit', handleEditShopSubmit);
}

// Custom Fetch Wrapper with Token Auth & Auto Logout
async function apiCall(endpoint, options = {}) {
  const headers = options.headers || {};
  if (state.token) {
    headers['Authorization'] = `Bearer ${state.token}`;
  }
  
  const mergedOptions = {
    ...options,
    headers
  };
  
  try {
    const response = await fetch(`${API_BASE}${endpoint}`, mergedOptions);
    
    // Auto logout on token expiration/unauthorized
    if (response.status === 401) {
      handleLogout();
      showToast('सत्र समाप्त', 'कृपया पुन्हा लॉगिन करा.', 'error');
      throw new Error('Unauthorized');
    }
    
    const data = await response.json();
    if (!response.ok || data.success === false) {
      throw new Error(data.message || data.error || 'API Request Failed');
    }
    return data;
  } catch (err) {
    console.error(`API Call error to ${endpoint}:`, err);
    throw err;
  }
}

// Authentication Handlers
async function handleLogin(e) {
  e.preventDefault();
  el.loginError.classList.add('hidden');
  
  const mobile = el.loginMobile.value.trim();
  const password = el.loginPassword.value;
  
  try {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mobile, password })
    });
    
    const data = await res.json();
    if (!res.ok || data.status === 'fail') {
      throw new Error(data.message || 'Login failed');
    }
    
    const user = data.data.user;
    if (user.role !== 'admin' && user.role !== 'superuser' && !user.is_admin) {
      throw new Error('Admin Access Permited Only / केवळ ॲडमिनसाठी प्रवेश.');
    }
    
    state.token = data.data.accessToken;
    state.adminUser = user;
    localStorage.setItem('admin_token', state.token);
    
    showToast('लॉगिन यशस्वी', `स्वागत आहे ${user.full_name}!`, 'success');
    initializeDashboard();
  } catch (err) {
    el.loginError.textContent = err.message;
    el.loginError.classList.remove('hidden');
  }
}

function handleLogout() {
  state.token = null;
  state.adminUser = null;
  localStorage.removeItem('admin_token');
  if (state.sseSource) {
    state.sseSource.close();
    state.sseSource = null;
  }
  showLogin();
}

function showLogin() {
  el.adminPanel.classList.add('hidden');
  el.loginScreen.classList.remove('hidden');
}

function showDashboard() {
  el.loginScreen.classList.add('hidden');
  el.adminPanel.classList.remove('hidden');
}

// Initialize Application UI
async function initializeDashboard() {
  showDashboard();
  
  // Set Logged In Name
  try {
    const meRes = await apiCall('/auth/user/me');
    state.adminUser = meRes.data || { full_name: 'Administrator' };
    el.adminName.textContent = state.adminUser.full_name;
  } catch (e) {
    el.adminName.textContent = 'Administrator';
  }
  
  // Establish Real-time Claim Streams
  connectSSEStream();
  
  // Load data for active tab
  loadTabData();
}

// Switch Tabs
function switchTab(tabId) {
  state.activeTab = tabId;
  
  // Navigation Buttons Toggle
  el.navItems.forEach(item => {
    if (item.getAttribute('data-tab') === tabId) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });
  
  // Content View Toggle
  el.tabPanes.forEach(pane => {
    if (pane.id === `tab-${tabId}`) {
      pane.classList.add('active');
    } else {
      pane.classList.remove('active');
    }
  });
  
  loadTabData();
}

// Load Tab data dynamically
function loadTabData() {
  if (state.activeTab === 'dashboard') {
    loadDashboardStats();
  } else if (state.activeTab === 'shops') {
    loadShops();
  } else if (state.activeTab === 'claims') {
    loadClaims();
  }
}

// TAB 1: OVERVIEW DASHBOARD DATA LOAD
async function loadDashboardStats() {
  try {
    const shopsRes = await apiCall('/shops/admin/list');
    state.shops = shopsRes.shops || [];
    
    const claimsRes = await apiCall('/shops/admin/coin-claims');
    state.claims = claimsRes.claims || [];
    
    // Calculate values
    const totalShops = state.shops.length;
    const activeShops = state.shops.filter(s => s.status === 'active').length;
    const totalClaims = state.claims.length;
    
    // Render Stats counters with text update
    el.statTotalShops.textContent = totalShops;
    el.statActiveShops.textContent = activeShops;
    el.statTotalClaims.textContent = totalClaims;
    
    // Render Category Progress Metrics
    renderCategoryMetrics();
    
    // Render Initial Activity logs in Dashboard (Show last 5 claims)
    renderDashboardClaimLogs();
  } catch (err) {
    showToast('डेटा लोडिंग एरर', 'सांख्यिकी लोड करताना चूक झाली.', 'error');
  }
}

function renderCategoryMetrics() {
  const catCounts = {};
  Object.keys(CATEGORIES).forEach(k => catCounts[k] = 0);
  
  state.shops.forEach(shop => {
    let cats = [];
    try {
      cats = typeof shop.categories === 'string' ? JSON.parse(shop.categories) : shop.categories;
    } catch(e) {
      cats = [];
    }
    if (Array.isArray(cats)) {
      cats.forEach(c => {
        if (catCounts[c] !== undefined) catCounts[c]++;
      });
    }
  });
  
  const total = state.shops.length || 1;
  el.categoryMetricsList.innerHTML = '';
  
  Object.keys(catCounts).forEach(catKey => {
    const count = catCounts[catKey];
    const percentage = Math.round((count / total) * 100);
    const mrName = CATEGORIES[catKey].mr;
    
    const metricRow = document.createElement('div');
    metricRow.className = 'category-metric-row';
    metricRow.innerHTML = `
      <div class="category-metric-info">
        <span>${mrName} (${CATEGORIES[catKey].en})</span>
        <span>${count} दुकाने (${percentage}%)</span>
      </div>
      <div class="category-progress-track">
        <div class="category-progress-fill" style="width: ${percentage}%"></div>
      </div>
    `;
    el.categoryMetricsList.appendChild(metricRow);
  });
}

function renderDashboardClaimLogs() {
  const recent = state.claims.slice(0, 5);
  el.liveClaimStream.innerHTML = '';
  
  if (recent.length === 0) {
    el.liveClaimStream.innerHTML = `
      <div class="empty-state">
        <i class="fa-solid fa-wave-square"></i>
        <p>नवीन कॉईन क्लेम्सची वाट पाहत आहे...</p>
      </div>
    `;
    return;
  }
  
  recent.forEach(claim => {
    addClaimToStream(claim, false); // append at end
  });
}

// Add a claim block to Dashboard feed (EventSource or normal render)
function addClaimToStream(claim, prepend = true) {
  const dateObj = new Date(claim.created_at);
  const timeStr = dateObj.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  const initial = claim.user_name ? claim.user_name.charAt(0).toUpperCase() : 'F';
  
  const streamItem = document.createElement('div');
  streamItem.className = 'stream-item';
  streamItem.innerHTML = `
    <div class="stream-avatar-circle">${initial}</div>
    <div class="stream-details">
      <h4>${claim.user_name || 'शेतकरी'} (${claim.user_mobile || 'N/A'})</h4>
      <p>दुकान: <strong>${claim.shop_name || 'शेतकरी मार्केट'}</strong> (${claim.shop_city || ''})</p>
      <p>कोड: <span class="badge badge-success">${claim.claim_code}</span></p>
    </div>
    <div class="stream-amount">
      <div class="coins"><i class="fa-solid fa-coins"></i> -${claim.coins_redeemed}</div>
      <div class="time">${timeStr}</div>
    </div>
  `;
  
  if (prepend) {
    const empty = el.liveClaimStream.querySelector('.empty-state');
    if (empty) empty.remove();
    el.liveClaimStream.insertBefore(streamItem, el.liveClaimStream.firstChild);
  } else {
    el.liveClaimStream.appendChild(streamItem);
  }
}

// Server-Sent Events real-time stream connection
function connectSSEStream() {
  if (state.sseSource) {
    state.sseSource.close();
  }
  
  const streamUrl = `/api/v1/shops/admin/claims-stream?token=${state.token}`;
  state.sseSource = new EventSource(streamUrl);
  
  state.sseSource.onopen = () => {
    el.statusDot.className = 'status-dot pulsing';
    el.statusText.textContent = 'Real-time Connected';
    console.log('SSE Stream established successfully.');
  };
  
  state.sseSource.onerror = (e) => {
    el.statusDot.className = 'status-dot';
    el.statusDot.style.backgroundColor = '#d32f2f';
    el.statusDot.style.boxShadow = 'none';
    el.statusText.textContent = 'Stream Connection Lost... Reconnecting';
    console.warn('SSE Stream disconnected. Retrying...');
  };
  
  state.sseSource.onmessage = async (event) => {
    try {
      const claim = JSON.parse(event.data);
      console.log('SSE Claim Message Received:', claim);
      
      // Look up user/shop details to show in the live feed since the SSE broadcast is lean
      let enrichedClaim = { ...claim };
      try {
        const shopsRes = await apiCall('/shops/admin/list');
        const targetShop = (shopsRes.shops || []).find(s => s.id === claim.shop_id);
        if (targetShop) {
          enrichedClaim.shop_name = targetShop.name;
          enrichedClaim.shop_city = targetShop.city;
        }
      } catch(e) {}
      
      // Show desktop/window toaster notification
      showToast('नवीन कॉईन क्लेम! 🎟️', `शेतकऱ्याने ${enrichedClaim.coins_redeemed} कॉईन्स रिडीम केले.`, 'warning');
      
      // Update counters dynamically
      if (state.activeTab === 'dashboard') {
        const curr = parseInt(el.statTotalClaims.textContent) || 0;
        el.statTotalClaims.textContent = curr + 1;
        addClaimToStream(enrichedClaim, true); // Prepend to feed
      }
    } catch (err) {
      console.error('Error handling SSE message:', err);
    }
  };
}

// TAB 2: SHOP MANAGEMENT DATA LOAD
async function loadShops() {
  try {
    const res = await apiCall('/shops/admin/list');
    state.shops = res.shops || [];
    renderShopsTable();
  } catch (err) {
    showToast('दुकाने लोड एरर', 'दुकानांची यादी लोड करताना एरर आली.', 'error');
  }
}

function renderShopsTable() {
  const searchVal = el.shopSearch.value.toLowerCase().trim();
  const selectedCat = el.filterCategory.value;
  
  // Filter list
  const filtered = state.shops.filter(shop => {
    const matchesSearch = 
      shop.name.toLowerCase().includes(searchVal) ||
      (shop.owner_name && shop.owner_name.toLowerCase().includes(searchVal)) ||
      (shop.city && shop.city.toLowerCase().includes(searchVal)) ||
      (shop.pincode && shop.pincode.includes(searchVal));
      
    let matchesCat = true;
    if (selectedCat) {
      try {
        const cats = typeof shop.categories === 'string' ? JSON.parse(shop.categories) : shop.categories;
        matchesCat = Array.isArray(cats) && cats.includes(selectedCat);
      } catch (e) {
        matchesCat = false;
      }
    }
    return matchesSearch && matchesCat;
  });
  
  el.shopsCountBadge.textContent = `एकूण: ${filtered.length}`;
  el.shopRegistryRows.innerHTML = '';
  
  if (filtered.length === 0) {
    el.shopRegistryRows.innerHTML = `
      <tr>
        <td colspan="7" class="text-center" style="padding: 40px; text-align: center;">
          <i class="fa-solid fa-store-slash" style="font-size: 30px; color: var(--text-muted); margin-bottom: 12px; display: block;"></i>
          कोणतीही दुकाने आढळली नाहीत.
        </td>
      </tr>
    `;
    return;
  }
  
  filtered.forEach(shop => {
    const isActive = shop.status === 'active';
    const profileImg = shop.profile_photo 
      ? `<img class="table-avatar" src="${shop.profile_photo}" alt="Profile">`
      : `<div class="table-avatar-placeholder"><i class="fa-solid fa-store"></i></div>`;
      
    const coinsReq = shop.coins_required || 50;
    const discountPct = shop.discount_percentage || 5.0;
    
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>
        <div class="table-avatar-cell">
          ${profileImg}
          <div>
            <div class="table-shop-name">${shop.name}</div>
            <div class="table-shop-id">ID: ${shop.id}</div>
          </div>
        </div>
      </td>
      <td>${shop.owner_name || 'N/A'}</td>
      <td>${shop.city || 'N/A'}</td>
      <td>${shop.contact_mobile}</td>
      <td>
        <span style="font-weight: 600; color: var(--accent-gold);"><i class="fa-solid fa-coins"></i> ${coinsReq}</span> &rarr; 
        <span style="font-weight: 600; color: #81c784;">${discountPct}% Off</span>
      </td>
      <td>
        <span class="badge ${isActive ? 'badge-success' : 'badge-warning'}">${shop.status}</span>
      </td>
      <td>
        <div class="action-buttons-cell">
          <button class="btn-icon status-toggle" title="${isActive ? 'Deactivate' : 'Activate'}" onclick="toggleShopStatus(${shop.id}, '${shop.status}')">
            <i class="fa-solid ${isActive ? 'fa-ban' : 'fa-circle-check'}"></i>
          </button>
          <button class="btn-icon edit" title="Edit Profile" onclick="openEditModal(${shop.id})">
            <i class="fa-solid fa-pen-to-square"></i>
          </button>
          <button class="btn-icon delete" title="Soft Delete" onclick="deleteShop(${shop.id})">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </td>
    `;
    el.shopRegistryRows.appendChild(row);
  });
}

// TAB 3: COIN CLAIMS & LOGS DATA LOAD
async function loadClaims() {
  try {
    const res = await apiCall('/shops/admin/coin-claims');
    state.claims = res.claims || [];
    renderClaimsTable();
  } catch (err) {
    showToast('क्लेम लॉग लोड एरर', 'इतिहास लोड करताना चूक झाली.', 'error');
  }
}

function renderClaimsTable() {
  const searchVal = el.claimsSearch.value.toLowerCase().trim();
  
  const filtered = state.claims.filter(claim => {
    return (
      claim.claim_code.toLowerCase().includes(searchVal) ||
      (claim.user_name && claim.user_name.toLowerCase().includes(searchVal)) ||
      (claim.user_mobile && claim.user_mobile.includes(searchVal)) ||
      (claim.shop_name && claim.shop_name.toLowerCase().includes(searchVal)) ||
      (claim.shop_city && claim.shop_city.toLowerCase().includes(searchVal))
    );
  });
  
  el.claimsLogRows.innerHTML = '';
  
  if (filtered.length === 0) {
    el.claimsLogRows.innerHTML = `
      <tr>
        <td colspan="6" class="text-center" style="padding: 40px; text-align: center;">
          कोणताही इतिहास सापडला नाही.
        </td>
      </tr>
    `;
    return;
  }
  
  filtered.forEach(claim => {
    const dateStr = new Date(claim.created_at).toLocaleDateString('mr-IN', {
      year: 'numeric', month: 'long', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
    
    const row = document.createElement('tr');
    row.innerHTML = `
      <td><strong style="color: var(--accent-gold);">${claim.claim_code}</strong></td>
      <td>
        <div><strong>${claim.user_name}</strong></div>
        <div style="font-size: 11px; color: var(--text-muted);">${claim.user_mobile}</div>
      </td>
      <td>
        <div><strong>${claim.shop_name}</strong></div>
        <div style="font-size: 11px; color: var(--text-muted);">${claim.shop_city || ''}</div>
      </td>
      <td><span style="color: var(--accent-gold); font-weight: 600;"><i class="fa-solid fa-coins"></i> ${claim.coins_redeemed}</span></td>
      <td><span style="color: #81c784; font-weight: 600;">${claim.discount_percentage}%</span></td>
      <td><span style="font-size: 12px;">${dateStr}</span></td>
    `;
    el.claimsLogRows.appendChild(row);
  });
}

// Shop Status Toggles
async function toggleShopStatus(id, currentStatus) {
  const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
  try {
    await apiCall(`/shops/admin/${id}/update`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: newStatus })
    });
    showToast('स्थिती बदलली ✅', `दुकानाची स्थिती यशस्वीरीत्या ${newStatus} करण्यात आली.`, 'success');
    loadShops();
  } catch (err) {
    showToast('एरर', 'स्थिती बदलण्यात अडचण आली.', 'error');
  }
}

async function deleteShop(id) {
  if (!confirm('तुम्हाला हे दुकान डिलीट करायचे आहे का? (Soft Delete)')) return;
  try {
    await apiCall(`/shops/admin/${id}`, {
      method: 'DELETE'
    });
    showToast('दुकान काढले 🗑️', 'दुकान यशस्वीरीत्या हटवले गेले.', 'success');
    loadShops();
  } catch(err) {
    showToast('एरर', 'दुकान डिलीट करण्यात चूक झाली.', 'error');
  }
}

// Edit Modal Dialog Handling
async function openEditModal(shopId) {
  state.editingShopId = shopId;
  state.newProfileFile = null;
  state.newGalleryFiles = [];
  el.editProfileInput.value = '';
  el.editGalleryInput.value = '';
  
  try {
    const shop = state.shops.find(s => s.id === shopId);
    if (!shop) return;
    
    // Fill Text Inputs
    el.editShopId.value = shop.id;
    el.editShopName.value = shop.name;
    el.editOwnerName.value = shop.owner_name || '';
    el.editCity.value = shop.city || '';
    el.editPincode.value = shop.pincode || '';
    el.editAddress.value = shop.address || '';
    el.editMobile.value = shop.contact_mobile || '';
    el.editWhatsapp.value = shop.whatsapp_number || '';
    el.editServices.value = shop.services || '';
    el.editCoinsRequired.value = shop.coins_required || 50;
    el.editDiscountPercentage.value = shop.discount_percentage || 5.0;
    
    // Profile photo preview
    el.editProfilePreview.src = shop.profile_photo || '';
    
    // Checkboxes Categories
    let cats = [];
    try {
      cats = typeof shop.categories === 'string' ? JSON.parse(shop.categories) : shop.categories;
    } catch(e) {
      cats = [];
    }
    const checkboxes = el.editShopForm.querySelectorAll('input[name="categories"]');
    checkboxes.forEach(box => {
      box.checked = Array.isArray(cats) && cats.includes(box.value);
    });
    
    // Existing Gallery images
    let gallery = [];
    try {
      gallery = typeof shop.images === 'string' ? JSON.parse(shop.images) : shop.images;
    } catch(e) {
      gallery = [];
    }
    state.existingImages = Array.isArray(gallery) ? gallery : [];
    
    renderGalleryGrid();
    el.editShopModal.classList.remove('hidden');
  } catch (err) {
    showToast('एडिट एरर', 'दुकानाची माहिती मिळवता आली नाही.', 'error');
  }
}

function closeEditModal() {
  el.editShopModal.classList.add('hidden');
  state.editingShopId = null;
  state.existingImages = [];
  state.newProfileFile = null;
  state.newGalleryFiles = [];
}

// Render Gallery list inside edit Modal
function renderGalleryGrid() {
  el.galleryPreviewsContainer.innerHTML = '';
  
  // 1. Render Existing Images on server
  state.existingImages.forEach((imgUrl, index) => {
    const item = document.createElement('div');
    item.className = 'gallery-preview-item';
    item.innerHTML = `
      <img src="${imgUrl}" alt="Gallery Image">
      <div class="gallery-delete-overlay" onclick="removeExistingGalleryImage(${index})">
        <i class="fa-solid fa-trash-can"></i>
      </div>
    `;
    el.galleryPreviewsContainer.appendChild(item);
  });
  
  // 2. Render locally added new images awaiting upload
  state.newGalleryFiles.forEach((file, index) => {
    const item = document.createElement('div');
    item.className = 'gallery-preview-item';
    item.style.border = '2px dashed var(--accent-gold)';
    item.innerHTML = `
      <img src="${URL.createObjectURL(file)}" alt="Awaiting Upload">
      <div class="gallery-delete-overlay" onclick="removeNewGalleryImage(${index})">
        <i class="fa-solid fa-xmark"></i>
      </div>
    `;
    el.galleryPreviewsContainer.appendChild(item);
  });
}

function removeExistingGalleryImage(index) {
  state.existingImages.splice(index, 1);
  renderGalleryGrid();
}

function removeNewGalleryImage(index) {
  state.newGalleryFiles.splice(index, 1);
  renderGalleryGrid();
}

// Save Modifications (Form Submit Multipart/form-data)
async function handleEditShopSubmit(e) {
  e.preventDefault();
  
  const btn = el.editShopForm.querySelector('#btn-save-shop');
  const originalText = btn.innerHTML;
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i> जतन होत आहे...';
  
  // Retrieve selected checkboxes
  const selectedCats = [];
  el.editShopForm.querySelectorAll('input[name="categories"]:checked').forEach(box => {
    selectedCats.push(box.value);
  });
  
  if (selectedCats.length === 0) {
    showToast('वर्गवारी एरर', 'कृपया किमान एक वर्ग निवडा!', 'error');
    btn.disabled = false;
    btn.innerHTML = originalText;
    return;
  }
  
  // Construct FormData
  const fd = new FormData();
  fd.append('name', el.editShopName.value.trim());
  fd.append('owner_name', el.editOwnerName.value.trim());
  fd.append('city', el.editCity.value.trim());
  fd.append('pincode', el.editPincode.value.trim());
  fd.append('address', el.editAddress.value.trim());
  fd.append('contact_mobile', el.editMobile.value.trim());
  fd.append('whatsapp_number', el.editWhatsapp.value.trim() || el.editMobile.value.trim());
  fd.append('services', el.editServices.value.trim());
  fd.append('coins_required', parseInt(el.editCoinsRequired.value));
  fd.append('discount_percentage', parseFloat(el.editDiscountPercentage.value));
  fd.append('categories', JSON.stringify(selectedCats));
  
  // Send list of remaining existing image URLs on server
  fd.append('existing_images', JSON.stringify(state.existingImages));
  
  // Append new profile file
  if (state.newProfileFile) {
    fd.append('profile_photo', state.newProfileFile);
  } else if (el.editProfilePreview.src === '' || el.editProfilePreview.src.endsWith('/admin-dashboard/') || el.editProfilePreview.src.endsWith('/admin/')) {
    // Explicitly clearing profile photo
    fd.append('profile_photo', '');
  }
  
  // Append new gallery files
  state.newGalleryFiles.forEach(file => {
    fd.append('images', file);
  });
  
  try {
    const headers = { 'Authorization': `Bearer ${state.token}` };
    const response = await fetch(`${API_BASE}/shops/admin/${state.editingShopId}/update`, {
      method: 'PUT',
      headers,
      body: fd
    });
    
    const data = await response.json();
    if (!response.ok || data.success === false) {
      throw new Error(data.message || 'Update failed');
    }
    
    showToast('माहिती जतन केली ✅', 'दुकान तपशील यशस्वीरीत्या अपडेट करण्यात आला आहे.', 'success');
    closeEditModal();
    loadShops();
  } catch (err) {
    showToast('अपडेट अपयशी', err.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = originalText;
  }
}

// Toast Notifications display helper
function showToast(title, message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = 'toast';
  
  let iconClass = 'fa-circle-check';
  if (type === 'error') {
    iconClass = 'fa-circle-exclamation';
    toast.style.borderLeftColor = 'var(--danger)';
  } else if (type === 'warning') {
    iconClass = 'fa-ticket';
    toast.style.borderLeftColor = 'var(--warning)';
  }
  
  toast.innerHTML = `
    <div class="toast-icon">
      <i class="fa-solid ${iconClass}"></i>
    </div>
    <div class="toast-body">
      <h4>${title}</h4>
      <p>${message}</p>
    </div>
  `;
  
  el.toastContainer.appendChild(toast);
  
  // Remove toast automatically
  setTimeout(() => {
    toast.style.animation = 'slide-in-toast 0.4s ease reverse forwards';
    setTimeout(() => toast.remove(), 400);
  }, 5000);
}
