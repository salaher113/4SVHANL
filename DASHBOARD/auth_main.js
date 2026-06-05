// ============================================================
// CLICK CART Admin Dashboard — auth.js (v2 robust)
// ============================================================

// ── Security: Disable DevTools ────────────────────────────────
document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('keydown', function(e) {
  if (
    e.key === 'F12' ||
    (e.ctrlKey && e.shiftKey && ['I','J','C','K'].includes(e.key.toUpperCase())) ||
    (e.ctrlKey && e.key === 'U')
  ) {
    e.preventDefault();
    return false;
  }
});

// ── Passive DevTools Freezer
setInterval(function() {
    debugger;
}, 50);


// ── Global helpers (available before Supabase loads) ─────────
function showError(msg) {
  var el = document.getElementById('loginError');
  if (el) { 
    el.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width:16px;height:16px;display:inline-block;vertical-align:middle;margin-right:6px;margin-top:-2px;"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>' + msg; 
    el.classList.add('show'); 
  }
}
function hideError() {
  var el = document.getElementById('loginError');
  if (el) el.classList.remove('show');
}
function setBtn(text, disabled) {
  var btn = document.getElementById('loginBtn');
  if (btn) { btn.textContent = text; btn.disabled = !!disabled; }
}

// ── Main login function — called by onclick on button ─────────
async function doLogin() {
  hideError();

  var emailInput = document.getElementById('emailInput');
  var passInput  = document.getElementById('passInput');

  if (!emailInput || !passInput) {
    showError('Page error: inputs not found. Refresh the page.');
    return;
  }

  var username = (emailInput.value || '').trim().toLowerCase();
  var password = (passInput.value || '');

  if (!username) { showError('Please enter your username.'); return; }
  if (!password) { showError('Please enter your password.'); return; }

  var fullEmail = username.includes('@') ? username : (username + '@gopremium.com');

  setBtn('Signing in…', true);

  // Check Supabase is available
  if (typeof window.supabase === 'undefined') {
    showError('Connection error: Supabase library not loaded. Check your internet connection and refresh.');
    setBtn('Sign In', false);
    return;
  }

  var client;
  try {
    client = window.supabase.createClient(
      'https://bmpfpvxprhazwuhogkcf.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtcGZwdnhwcmhhend1aG9na2NmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgyMDc1MCwiZXhwIjoyMDg1Mzk2NzUwfQ.VgFeGNGL51R3WyC1jrvMU86YaqxEp_voyKOoIY-psLg',
      { auth: { autoRefreshToken: false, persistSession: false } }
    );
  } catch (e) {
    showError('Failed to initialize connection: ' + e.message);
    setBtn('Sign In', false);
    return;
  }

  try {
    // ── Mock Login For OWNER ──
    if (username.toLowerCase() === 'salahdin' || username.toLowerCase() === 'salahdin@joy.tv' || username.toLowerCase() === 'salahdin@gopremium.com') {
        if (password === 'SALAHDIN300') {
            sessionStorage.setItem('admin_token', 'mock_owner_token_12345');
            sessionStorage.setItem('admin_id', 'owner-001');
            sessionStorage.setItem('admin_name', 'SALAHDIN');
            sessionStorage.setItem('admin_role', 'owner');
            sessionStorage.setItem('admin_email', 'salahdin@joy.tv');
            
            var perms = { view_users: true, view_reports: true, create_users: true, edit_ban: true };
            sessionStorage.setItem('admin_permissions', JSON.stringify(perms));
            
            setBtn('Redirecting…', true);
            window.location.href = 'dashboard.html';
            return;
        } else {
            showError('Invalid email or password.');
            setBtn('Sign In', false);
            return;
        }
    }

    // ── Normal Supabase Login ──
    const { data: authData, error: authErr } = await client.auth.signInWithPassword({
        email: fullEmail,
        password: password
    });

    if (authErr) {
        showError('Invalid email or password.');
        setBtn('Sign In', false);
        return;
    }

    // Fetch profile
    const { data: profile } = await client
        .from('profiles')
        .select('*')
        .eq('id', authData.user.id)
        .single();

    const role = profile ? profile.role : 'admin';
    const name = profile ? profile.username : fullEmail.split('@')[0];

    // ── Success: store session and redirect ──
    var token = authData.session.access_token;

    sessionStorage.setItem('admin_token', token);
    sessionStorage.setItem('admin_id', authData.user.id);
    sessionStorage.setItem('admin_name', name);
    sessionStorage.setItem('admin_role', role);
    sessionStorage.setItem('admin_email', fullEmail);
    
    // Store advanced permissions
    var perms = { view_users: true, view_reports: true, create_users: true, edit_ban: true };
    sessionStorage.setItem('admin_permissions', JSON.stringify(perms));

    setBtn('Redirecting…', true);
    window.location.href = 'dashboard.html';

  } catch (err) {
    var msg = (err && err.message) ? err.message : String(err);
    showError('Login failed: ' + msg);
    setBtn('Sign In', false);
  }
}

// ── Toggle password visibility ────────────────────────────────
window.addEventListener('DOMContentLoaded', function() {
  // Enter key support
  var emailInput = document.getElementById('emailInput');
  var passInput  = document.getElementById('passInput');
  if (emailInput) emailInput.addEventListener('keydown', function(e) { if (e.key === 'Enter') doLogin(); });
  if (passInput)  passInput.addEventListener('keydown',  function(e) { if (e.key === 'Enter') doLogin(); });

  // Toggle password
  var toggleBtn = document.getElementById('togglePass');
  if (toggleBtn && passInput) {
    toggleBtn.addEventListener('click', function() {
      var isPass = passInput.type === 'password';
      passInput.type = isPass ? 'text' : 'password';
      toggleBtn.innerHTML = isPass 
        ? '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" /></svg>'
        : '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width:18px;height:18px;"><path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" /><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>';
    });
  }

  // Redirect if already logged in
  if (sessionStorage.getItem('admin_token')) {
    window.location.href = 'dashboard.html';
  }
});
