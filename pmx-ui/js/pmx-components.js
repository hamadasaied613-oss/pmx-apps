const PMX = {
  currentTheme: 'default',
  themes: ['default','boq','feasibility','pmo','contract','bim','dashboard','inspector','cad2bim','knowledge'],
  chartLoaded: false,
  toastContainer: null,

  DEMO_DATA: {
    boq: { activeBoqs: 12, totalValue: '2,450,000', avgTime: '45s', items: [
      ['Villa Al Wasl', 156, '1,850,000', 'Active', '2026-06-28'],
      ['Tower JLT Phase 2', 423, '12,400,000', 'Under Review', '2026-06-25'],
      ['School Al Ain', 89, '980,000', 'Draft', '2026-06-20']
    ]},
    sign: { activeContracts: 8, riskItems: 2, expiringSoon: 1, items: [
      ['Main Construction', 'AL JABER GROUP', '8,500,000', 'Active', '2027-12-31'],
      ['MEP Works', 'EMIRATES TECHNICAL', '2,300,000', 'Under Review', '2026-09-15'],
      ['Consultancy', 'DAR AL HANDASAH', '450,000', 'Expiring', '2026-07-30']
    ]},
    focus: { studiesCompleted: 15, investmentAnalyzed: '45,000,000', avgRoi: '18.5%', items: [
      ['Residential Compound', '12,000,000', '22.3%', 'Completed', '2026-06-15'],
      ['Commercial Tower', '25,000,000', '15.8%', 'Under Study', '2026-07-01'],
      ['Warehouse Complex', '8,000,000', '19.2%', 'Completed', '2026-05-30']
    ]},
    pilot: { activeProjects: 6, onTrack: '75%', atRisk: 1, items: [
      ['Al Wasl Villa', '1,850,000', '65%', 'On Track', '2026-09-30'],
      ['JLT Tower', '12,400,000', '30%', 'On Track', '2027-03-15'],
      ['School Project', '980,000', '90%', 'At Risk', '2026-07-15']
    ]},
    build: { activeModels: 4, clashesDetected: 23, qtyExtractions: 8, items: [
      ['Tower Structural', 'v2.1', '12,450', 'Reviewed', '2026-06-28'],
      ['MEP Model', 'v1.3', '8,230', 'Clash Detected', '2026-06-25'],
      ['Facade Model', 'v1.0', '3,560', 'Processing', '2026-06-22']
    ]},
    view: { portfolioHealth: '72%', activeProjects: 6, alerts: 3, items: [
      ['Schedule Performance', '0.85', '1.0', 'Behind', '▽'],
      ['Cost Performance', '0.92', '1.0', 'On Budget', '△'],
      ['Quality Index', '88%', '85%', 'Exceeding', '△']
    ]},
    site: { openInspections: 7, punchItems: 34, completedToday: 3, items: [
      ['Floor 12 Finishing', 'Ahmed Hassan', 12, 'Open', '2026-06-30'],
      ['MEP Check', 'Saeed Ali', 8, 'Partial', '2026-06-29'],
      ['Facade Review', 'Khaled Omar', 14, 'Open', '2026-06-28']
    ]},
    link: { conversions: 22, avgProcessing: '3m 12s', modelsGenerated: 18, items: [
      ['AL-WASL-MAIN.dwg', 'IFC', '4,560', 'Completed', '2026-06-29'],
      ['JLT-TOWER.dxf', 'RVT', '12,300', 'Completed', '2026-06-27'],
      ['SCHOOL-AIN.dwg', 'IFC', '2,890', 'Processing', '2026-06-30']
    ]},
    wise: { articles: 47, standards: 23, activeUsers: 5, items: [
      ['UAE Fire Code 2024', 'Regulations', 'Standard', 'Published', '2026-06-25'],
      ['Concrete Mix Design Guide', 'Materials', 'Article', 'Published', '2026-06-20'],
      ['BIM Execution Plan v2', 'Process', 'Template', 'Draft', '2026-06-28']
    ]}
  },

  init() {
    this.loadTheme();
    this.initThemeToggle();
    this.initWhatsApp();
    this.initCarouselScroll();
    this.initSidenav();
    this.initToastContainer();
    this.loadDemoData();
    this.initPrintTriggers();
    this.loadAppState();
  },

  loadTheme() {
    const saved = localStorage.getItem('pmx-theme');
    if (saved && this.themes.includes(saved)) {
      this.setTheme(saved, false);
    }
  },

  setTheme(name, save = true) {
    this.currentTheme = name;
    document.documentElement.setAttribute('data-theme', name === 'default' ? '' : name);
    document.querySelectorAll('.pmx-theme-dot').forEach(dot => {
      dot.classList.toggle('active', dot.dataset.theme === name);
    });
    if (save) localStorage.setItem('pmx-theme', name);
  },

  initThemeToggle() {
    document.querySelectorAll('.pmx-theme-dot').forEach(dot => {
      dot.addEventListener('click', () => this.setTheme(dot.dataset.theme));
    });
  },

  initWhatsApp() {
    const btn = document.querySelector('.pmx-whatsapp-btn');
    const panel = document.querySelector('.pmx-whatsapp-panel');
    if (btn && panel) {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        panel.classList.toggle('open');
      });
      document.addEventListener('click', () => panel.classList.remove('open'));
      panel.addEventListener('click', (e) => e.stopPropagation());
    }
  },

  initCarouselScroll() {
    const tracks = document.querySelectorAll('.pmx-carousel-track');
    tracks.forEach(track => {
      let isDown = false, startX, scrollLeft;
      track.addEventListener('mousedown', (e) => {
        isDown = true;
        startX = e.pageX - track.offsetLeft;
        scrollLeft = track.scrollLeft;
      });
      track.addEventListener('mouseleave', () => isDown = false);
      track.addEventListener('mouseup', () => isDown = false);
      track.addEventListener('mousemove', (e) => {
        if (!isDown) return;
        e.preventDefault();
        const x = e.pageX - track.offsetLeft;
        const walk = (x - startX) * 2;
        track.scrollLeft = scrollLeft - walk;
      });
    });
  },

  initSidenav() {
    document.querySelectorAll('.pmx-sidenav-item').forEach(item => {
      item.addEventListener('click', function() {
        document.querySelectorAll('.pmx-sidenav-item').forEach(i => i.classList.remove('active'));
        this.classList.add('active');
      });
    });
  },

  initToastContainer() {
    if (!document.querySelector('.pmx-toast-container')) {
      this.toastContainer = document.createElement('div');
      this.toastContainer.className = 'pmx-toast-container';
      document.body.appendChild(this.toastContainer);
    } else {
      this.toastContainer = document.querySelector('.pmx-toast-container');
    }
  },

  loadDemoData() {
    const app = document.documentElement.getAttribute('data-theme');
    if (!app || app === 'default') return;
    const data = this.DEMO_DATA[app === 'contract' ? 'sign' : app === 'feasibility' ? 'focus' : app === 'pmo' ? 'pilot' : app === 'bim' ? 'build' : app === 'dashboard' ? 'view' : app === 'inspector' ? 'site' : app === 'cad2bim' ? 'link' : app === 'knowledge' ? 'wise' : app];
    if (!data) return;

    const kpis = document.querySelectorAll('.pmx-kpi-card');
    if (kpis.length >= 3) {
      const keys = Object.keys(data).filter(k => !Array.isArray(data[k]) && k !== 'items');
      kpis.forEach((card, i) => {
        if (i < keys.length) {
          const val = card.querySelector('.pmx-kpi-value');
          if (val) val.textContent = data[keys[i]];
        }
      });
    }

    const tbody = document.querySelector('.pmx-table tbody');
    if (tbody && data.items && data.items.length) {
      tbody.innerHTML = data.items.map((row, ri) =>
        `<tr>${row.map(cell => `<td>${cell}</td>`).join('')}</tr>`
      ).join('');
    }
    this.addDemoBadge();
  },

  addDemoBadge() {
    if (!document.querySelector('.pmx-demo-badge')) {
      const badge = document.createElement('div');
      badge.className = 'pmx-demo-badge';
      badge.textContent = '🔬 Demo Data · النظام يعرض بيانات تجريبية';
      document.body.appendChild(badge);
    }
  },

  loadAppState() {
    const app = document.documentElement.getAttribute('data-theme');
    if (!app) return;
    const key = `pmx-${app}-state`;
    const saved = localStorage.getItem(key);
    if (saved) {
      try {
        const state = JSON.parse(saved);
        Object.keys(state).forEach(field => {
          const el = document.getElementById(field) || document.querySelector(`[name="${field}"]`);
          if (el) el.value = state[field];
        });
      } catch (e) { /* ignore corrupt state */ }
    }
  },

  saveAppState() {
    const app = document.documentElement.getAttribute('data-theme');
    if (!app) return;
    const inputs = document.querySelectorAll('input, select, textarea');
    const state = {};
    inputs.forEach(inp => { if (inp.id) state[inp.id] = inp.value; });
    localStorage.setItem(`pmx-${app}-state`, JSON.stringify(state));
  },

  loadChartJs(callback) {
    if (this.chartLoaded) { if (callback) callback(); return; }
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js';
    s.onload = () => { this.chartLoaded = true; if (callback) callback(); };
    s.onerror = () => this.showToast('Failed to load Chart.js', 'error');
    document.head.appendChild(s);
  },

  showToast(message, type = 'success') {
    if (!this.toastContainer) this.initToastContainer();
    const icons = { success: '✅', error: '⚠️', warning: '⚡', info: 'ℹ️' };
    const el = document.createElement('div');
    el.className = `pmx-toast pmx-toast-${type}`;
    el.innerHTML = `<span class="pmx-toast-icon">${icons[type] || 'ℹ️'}</span><span>${message}</span>`;
    this.toastContainer.appendChild(el);
    requestAnimationFrame(() => el.classList.add('open'));
    setTimeout(() => {
      el.classList.remove('open');
      setTimeout(() => el.remove(), 300);
    }, 3500);
  },

  formatCurrency(amount, currency = 'AED') {
    return new Intl.NumberFormat('ar-AE', { style: 'currency', currency }).format(amount);
  },

  formatNumber(num) {
    return new Intl.NumberFormat().format(num);
  },

  showNotification(message, type = 'success') {
    this.showToast(message, type);
  },

  initPrintTriggers() {
    document.querySelectorAll('[data-print]').forEach(btn => {
      btn.addEventListener('click', () => window.print());
    });
  }
};

document.addEventListener('DOMContentLoaded', () => PMX.init());
