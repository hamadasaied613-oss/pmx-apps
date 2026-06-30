const PMX = {
  currentTheme: 'default',
  themes: ['default','boq','feasibility','pmo','contract','bim','dashboard','inspector','cad2bim','knowledge'],

  init() {
    this.loadTheme();
    this.initThemeToggle();
    this.initWhatsApp();
    this.initCarouselScroll();
    this.initSidenav();
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

  formatCurrency(amount, currency = 'AED') {
    return new Intl.NumberFormat('ar-AE', { style: 'currency', currency }).format(amount);
  },

  formatNumber(num) {
    return new Intl.NumberFormat().format(num);
  },

  showNotification(message, type = 'success') {
    const colors = { success: '#27AE60', error: '#E74C3C', warning: '#F39C12', info: '#2980B9' };
    const el = document.createElement('div');
    el.textContent = message;
    Object.assign(el.style, {
      position: 'fixed', top: '20px', right: '20px',
      background: colors[type] || colors.info,
      color: '#fff', padding: '12px 24px', borderRadius: '8px',
      fontFamily: this.font || "'Segoe UI', sans-serif",
      fontSize: '14px', fontWeight: '600', zIndex: '9999',
      boxShadow: '0 4px 20px rgba(0,0,0,0.3)',
      transform: 'translateX(120%)', transition: 'transform 0.3s ease'
    });
    document.body.appendChild(el);
    requestAnimationFrame(() => el.style.transform = 'translateX(0)');
    setTimeout(() => {
      el.style.transform = 'translateX(120%)';
      setTimeout(() => el.remove(), 300);
    }, 3000);
  }
};

document.addEventListener('DOMContentLoaded', () => PMX.init());
