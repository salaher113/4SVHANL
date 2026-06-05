// ============================================================
// CLICK CART Admin Dashboard — dashboard.js (Neon CRM)
// ============================================================

// ── Security: Disable DevTools
document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('keydown', function(e) {
  if ( e.key === 'F12' || (e.ctrlKey && e.shiftKey && ['I','J','C','K'].includes(e.key.toUpperCase())) || (e.ctrlKey && e.key === 'U') ) {
    e.preventDefault(); return false;
  }
});

// ── Passive DevTools Freezer
setInterval(function() {
    debugger;
}, 50);



// ── Authentication Check
const token = sessionStorage.getItem('admin_token');
if (!token) { window.location.href = 'index.html'; }

const adminRole = sessionStorage.getItem('admin_role') || 'admin';
const adminEmail = sessionStorage.getItem('admin_email') || '';
const isSuperAdmin = (adminRole === 'owner' || adminRole === 'super_admin' || adminRole === 'superadmin' || adminEmail === 'admin@joy.tv' || adminEmail === 'salahdin@joy.tv');

// ── Permissions Parser
let adminPerms = { view_users: true, view_reports: true, create_users: true, edit_ban: true };
if (!isSuperAdmin) {
    try { 
        adminPerms = JSON.parse(sessionStorage.getItem('admin_permissions')) || adminPerms;
    } catch(e) {}
}

// ── Initialize Supabase
const SUPABASE_URL = 'https://bmpfpvxprhazwuhogkcf.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtcGZwdnhwcmhhend1aG9na2NmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgyMDc1MCwiZXhwIjoyMDg1Mzk2NzUwfQ.VgFeGNGL51R3WyC1jrvMU86YaqxEp_voyKOoIY-psLg';
let dbClient;

function getSupabase() {
    if (!dbClient) dbClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { autoRefreshToken: false, persistSession: false } });
    return dbClient;
}

// ── Colors for Charts
const colorFocus = '#8B5CF6'; 
const colorSubdued = '#06B6D4'; 
const colorMuted = '#334155'; 
const colorGrid = 'rgba(255,255,255,0.04)';
const colorText = '#94A3B8';

let cMain, cArea, cBar;

console.log("Dashboard JS Loaded");

// Topbar & Admin Menu Logic
const adminName = sessionStorage.getItem('admin_name') || 'Admin';
const initial = adminName.charAt(0).toUpperCase();

document.getElementById('tp-name-text').textContent = adminName;
document.getElementById('tp-avatar-text').textContent = initial;

// Reveal Admin Portal if Super Admin
if (isSuperAdmin) {
    document.getElementById('menuAdminMgmt').style.display = 'flex';
}

// Navigation setup
document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
        if (link.dataset.page) {
            e.preventDefault();
            navigate(link.dataset.page);
        }
    });

    // Permission Enforcement
    if (!isSuperAdmin) {
        if (!adminPerms.view_users && link.dataset.page === 'users') link.style.display = 'none';
        if (!adminPerms.view_reports && link.dataset.page === 'reports') link.style.display = 'none';
        if (!adminPerms.create_users && link.dataset.page === 'create-user') link.style.display = 'none';
    }
});

navigate('overview');
setupRealtimeSubscriptions();

function logout() { sessionStorage.clear(); window.location.href = 'index.html'; }

function navigate(pageId) {
    document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
    document.querySelectorAll('.view-section').forEach(s => s.classList.remove('active'));
    
    document.querySelector(`.nav-link[data-page="${pageId}"]`)?.classList.add('active');
    document.getElementById(`page-${pageId}`)?.classList.add('active');

    const titles = {
        'overview': 'CRM Metrics Overview',
        'reports': 'User Feedback & Reports',
        'users': 'Global User Registry',
        'create-user': 'Secure Account Provisioning',
        'admins': 'Super Admin Management'
    };
    document.getElementById('pageTitle').textContent = titles[pageId] || 'Dashboard';

    if (pageId === 'overview') loadOverview();
    if (pageId === 'users') loadUsers();
    if (pageId === 'reports') loadReports();
    if (pageId === 'admins') { loadAdmins(); loadLogs(); }
    if (pageId === 'create-user') loadCreateUser();
}

function toast(msg, isError=false) { alert((isError ? '❌ ' : '✅ ') + msg); }
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric', hour:'2-digit', minute:'2-digit' }) : '—'; }

// ==============================================================
// LOGGER SYSTEM (Phase 2)
// ==============================================================
async function logAdminAction(action_type, target) {
    try {
        const db = getSupabase();
        const aId = sessionStorage.getItem('admin_id') || 'UNKNOWN';
        const aName = sessionStorage.getItem('admin_name') || 'Admin';
        
        await db.from('admin_logs').insert({
            admin_id: aId,
            admin_name: aName,
            action_type: action_type,
            target: target
        });
    } catch(e) { console.error("Logger Failed:", e); }
}

// ==============================================================
// POINTS SYSTEM AUTHENTICATION
// ==============================================================
async function checkAndDeductPoint() {
    if (isSuperAdmin) return true; // Super Admins bypass points

    const db = getSupabase();
    // 1. Fetch current points mapping to this email
    const { data: profile, error } = await db.from('profiles').select('id, points').eq('email', adminEmail).single();
    if (error || !profile) {
        toast("Access Error: Cannot verify your points allocation.", true);
        return false;
    }
    
    let currentPts = profile.points || 0;
    if (currentPts <= 0) {
        toast("Action Denied: Insufficient Account Points. Contact Super Admin.", true);
        return false;
    }

    // 2. Deduct 1 point
    const { error: updErr } = await db.from('profiles').update({ points: currentPts - 1 }).eq('id', profile.id);
    if (updErr) {
        toast("Transaction Failed: Could not process point deduction.", true);
        return false;
    }
    return true;
}

// ==============================================================
// REALTIME SUBSCRIPTIONS
// ==============================================================
function setupRealtimeSubscriptions() {
    const db = getSupabase();
    db.channel('public-tracker')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, payload => {
          loadOverview();
          if(document.getElementById('page-users').classList.contains('active')) loadUsers();
          if(document.getElementById('page-admins').classList.contains('active')) loadAdmins();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'reports' }, payload => {
          if(document.getElementById('page-reports').classList.contains('active')) loadReports();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'admin_logs' }, payload => {
          if(document.getElementById('page-admins').classList.contains('active')) loadLogs();
      })
      .subscribe();
}

// ==============================================================
// PAGE: OVERVIEW
// ==============================================================
async function loadOverview() { /* existing logic */ 
    try {
        const db = getSupabase();
        const { data: profiles, error } = await db.from('profiles').select('*');
        if (!error && profiles) {
            document.getElementById('statTotalUsers').innerHTML = `${profiles.length} <sub>users</sub>`;
            
            let newToday=0, activeToday=0, bannedPct=0, adminRatio=0;
            const startOfDay = new Date(new Date().setHours(0,0,0,0));
            
            profiles.forEach(p => {
                if(new Date(p.created_at) >= startOfDay) newToday++;
                if(p.updated_at && new Date(p.updated_at) >= startOfDay) activeToday++;
                if(p.is_banned) bannedPct++;
                if(p.role === 'admin' || p.role === 'super_admin') adminRatio++;
            });
            
            document.getElementById('statNewToday').innerHTML = `${newToday} <sub>today</sub>`;
            document.getElementById('statActiveToday').textContent = activeToday;
            
            let aPct = profiles.length > 0 ? Math.round((adminRatio / profiles.length) * 100) : 0;
            document.getElementById('statRolePct').textContent = `${aPct}%`;
            document.getElementById('lblRoleAdmin').getContext ? null : document.getElementById('lblRoleAdmin').textContent = `Admin (${aPct}%)`;
            document.getElementById('lblRoleUser').textContent = `User (${100 - aPct}%)`;
            document.getElementById('statBanPct').textContent = `${profiles.length ? Math.round((bannedPct/profiles.length)*100) : 0}%`;
        }
        const { count: pend } = await db.from('reports').select('*', { count: 'exact', head: true }).eq('status', 'pending');
        document.getElementById('sidebar-report-badge').style.display = pend > 0 ? 'block' : 'none';
        document.getElementById('sidebar-report-badge').textContent = pend || 0;
        
        loadTopActiveUsers();
        setTimeout(renderCharts, 100);
    } catch (e) {}
}

async function loadTopActiveUsers() {
    try {
        const db = getSupabase();
        const { data, error } = await db.from('profiles').select('*').order('updated_at', { ascending: false }).limit(6);
        if(!error && data) {
            document.getElementById('topActiveUsersBody').innerHTML = data.map(u => {
                let av = u.avatar_url ? `<img src="${u.avatar_url}" style="width:24px;height:24px;border-radius:50%;object-fit:cover;">` : `<div style="width:24px;height:24px;border-radius:50%;background:var(--grad-purple);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:white;">${(u.username||'?').charAt(0).toUpperCase()}</div>`;
                return `<tr>
                    <td style="padding:8px 0;">
                        <div style="display:flex;align-items:center;gap:10px;">${av}
                            <div style="display:flex;flex-direction:column;">
                                <span style="color:white;font-weight:600;">${u.username||'User'}</span>
                                <span style="font-size:10px;color:var(--text-muted);">${u.email}</span>
                            </div>
                        </div>
                    </td><td style="color:var(--text-muted);text-align:right;">Active</td>
                </tr>`;
            }).join('');
        }
    } catch(e) {}
}

function renderCharts() {
    Chart.defaults.color = colorText;
    Chart.defaults.font.family = "'Poppins', sans-serif";
    const ctxMain = document.getElementById('chartMainLine').getContext('2d');
    if(cMain) cMain.destroy();
    const gradFocus = ctxMain.createLinearGradient(0,0,0,400); 
    gradFocus.addColorStop(0,'rgba(139,92,246,0.3)'); gradFocus.addColorStop(1,'rgba(139,92,246,0.0)');
    cMain = new Chart(ctxMain, { type: 'line', data: { labels: ['Jan','Feb','Mar','Apr','May','Jun','Jul'], datasets: [{ label:'Registrations', data:[30,42,38,55,48,65,59], borderColor:colorFocus, backgroundColor:gradFocus, borderWidth:2, tension:0.3, fill:true, pointBackgroundColor:colorFocus, pointBorderColor:'#000', pointBorderWidth:2, pointRadius:4 }, { label:'Watch Time', data:[15,25,20,45,30,50,45], borderColor:colorSubdued, borderWidth:2, tension:0.3, pointBackgroundColor:colorSubdued, pointBorderColor:'#000', pointBorderWidth:2, pointRadius:3 }] }, options: { responsive:true, maintainAspectRatio:false, plugins:{legend:{display:false}}, scales:{x:{grid:{color:colorGrid,drawBorder:false}},y:{grid:{color:colorGrid,drawBorder:false},beginAtZero:true}} } });
    
    const ctxArea = document.getElementById('chartAreaMini').getContext('2d');
    if(cArea) cArea.destroy();
    const gradArea = ctxArea.createLinearGradient(0,0,0,100); 
    gradArea.addColorStop(0,'rgba(139,92,246,0.4)'); gradArea.addColorStop(1,'rgba(139,92,246,0.0)');
    cArea = new Chart(ctxArea, { type:'line', data:{labels:['Mon','Tue','Wed','Thu','Fri','Sat','Sun'], datasets:[{data:[12,19,15,25,22,30,28],borderColor:colorFocus, backgroundColor:gradArea, borderWidth:2, tension:0.3, fill:true, pointRadius:0}]}, options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false},tooltip:{enabled:false}},scales:{x:{display:false},y:{display:false,min:0}}} });
}

// ==============================================================
// PAGE: CREATE USER ALGORITHM
// ==============================================================
function updateEmailPreview(val) {
    const safe = val.trim().toLowerCase().replace(/[^a-z0-9_]/g, '');
    document.getElementById('emailPreviewText').textContent = safe ? `${safe}@gopremium.com` : 'USERNAME@GOPREMIUM.COM';
    return safe;
}

function calcExpiry() {
    const y = parseInt(document.getElementById('durYears').value)||0, m = parseInt(document.getElementById('durMonths').value)||0, d = parseInt(document.getElementById('durDays').value)||0;
    const hr = parseInt(document.getElementById('durHours').value)||0, mn = parseInt(document.getElementById('durMins').value)||0, s = parseInt(document.getElementById('durSecs').value)||0;
    if (y > 0 || m > 0 || d > 0 || hr > 0 || mn > 0 || s > 0) {
        const date = new Date(); date.setFullYear(date.getFullYear()+y); date.setMonth(date.getMonth()+m); date.setDate(date.getDate()+d); date.setHours(date.getHours()+hr); date.setMinutes(date.getMinutes()+mn); date.setSeconds(date.getSeconds()+s);
        document.getElementById('expiryPreview').textContent = date.toLocaleString('en-US');
        return date.toISOString();
    } else { document.getElementById('expiryPreview').textContent = 'Permanent Access'; return null; }
}

async function createUser() {
    const rawUser = document.getElementById('cuUsername').value;
    const pass = document.getElementById('cuPassword').value;
    const safeUser = updateEmailPreview(rawUser);
    
    if (!safeUser || !pass) return toast('Please provide Alias and Password', true);
    if (pass.length < 6) return toast('Password min 6 chars', true);

    const email = `${safeUser}@gopremium.com`;
    const expiresAt = calcExpiry();

    if (!isSuperAdmin && !adminPerms.create_users) {
        return toast('Permission Denied: You cannot create user accounts.', true);
    }

    const btn = document.getElementById('createUserBtn');
    btn.textContent = 'Deploying...'; btn.disabled = true;

    try {
        // [PHASE 2 Check] - Deduct point if valid
        const pointsOk = await checkAndDeductPoint();
        if (!pointsOk) { btn.textContent = 'Deploy Profile'; btn.disabled = false; return; }

        const db = getSupabase();
        const { data, error } = await db.auth.signUp({
            email, password: pass,
            options: { data: { username: safeUser, role: 'user', account_expires_at: expiresAt } }
        });
        if (error) throw error;

        setTimeout(async () => {
            if (data?.user?.id) {
                await db.from('profiles').update({ 
                    username: safeUser, 
                    email: email,
                    account_expires_at: expiresAt, 
                    role: 'user', 
                    is_banned: false 
                }).eq('id', data.user.id);
                // [LOGGER]
                logAdminAction('Created user', safeUser);
            }
        }, 1500);

        toast(`Profile Deployed Successfully.`);
        document.getElementById('cuUsername').value = ''; document.getElementById('cuPassword').value = '';
        document.querySelectorAll('#durYears, #durMonths, #durDays, #durHours, #durMins, #durSecs').forEach(el => el.value = 0);
        updateEmailPreview('');
        loadCreateUser(); // Refresh the points display
        setTimeout(() => navigate('users'), 1000);
    } catch (e) { toast(e.message, true); }
    finally { btn.textContent = 'Deploy Profile'; btn.disabled = false; }
}

async function loadCreateUser() {
    const dDisp = document.getElementById('adminPointsDisplay');
    if (!dDisp) return;
    if (isSuperAdmin) {
        dDisp.innerHTML = `Points Balance: <span style="color:var(--neon-pink); font-weight:bold;">Infinite (∞)</span>`;
        return;
    }
    try {
        const db = getSupabase();
        const { data } = await db.from('profiles').select('points').eq('email', adminEmail).single();
        if (data) dDisp.innerHTML = `Points Balance: <span style="color:var(--neon-cyan); font-weight:bold;">${data.points || 0}</span>`;
    } catch(e) {}
}

// ==============================================================
// PAGE: USERS
// ==============================================================
let allUsers = [];
let timerInterval = null;

async function loadUsers() {
    const tb = document.getElementById('usersTableBody');
    tb.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">Syncing secure records...</td></tr>';
    try {
        const db = getSupabase();
        const { data, error } = await db.from('profiles').select('*').order('username', { ascending: true });
        if (error) return tb.innerHTML = `<tr><td colspan="6" style="color:var(--neon-pink)">Error: ${error.message}</td></tr>`;
        
        allUsers = data || [];
        renderUsersList(allUsers);
        if(timerInterval) clearInterval(timerInterval);
        timerInterval = setInterval(updateTimers, 1000);
    } catch(e) { tb.innerHTML = `<tr><td colspan="6" style="color:var(--neon-pink)">Init Error: ${e.message}</td></tr>`; }
}

function filterUsers(val) {
    const q = val.toLowerCase();
    renderUsersList(allUsers.filter(u => (u.username||'').toLowerCase().includes(q) || (u.email||'').toLowerCase().includes(q)));
}

function renderUsersList(users) {
    const tb = document.getElementById('usersTableBody');
    if (!users.length) return tb.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">No profiles located.</td></tr>';
    
    tb.innerHTML = users.map(u => {
        let status = u.is_banned ? `<span class="badge-tag t-red">BANNED</span>` : `<span class="badge-tag t-cyan">ACTIVE</span>`;
        let roleStyle = u.role==='admin' ? 't-purple' : (u.role==='super_admin' ? 't-pink' : 't-cyan');
        let av = u.avatar_url ? `<img src="${u.avatar_url}" style="width:32px;height:32px;border-radius:50%;object-fit:cover;box-shadow:var(--glow-purple)">` : `<div style="width:32px;height:32px;border-radius:50%;background:var(--grad-purple);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:white;box-shadow:var(--glow-purple)">${(u.username||'?').charAt(0).toUpperCase()}</div>`;
        const timeCell = u.account_expires_at ? `<span id="timer-${u.id}" style="font-family:monospace; font-size:14px; font-weight:700;">Calculating...</span>` : '<span style="color:var(--text-muted)">Permanent</span>';

        let actionBlock = '';
        if (isSuperAdmin || adminPerms.edit_ban) {
            actionBlock = `<div style="display:flex;gap:4px;">
                <button class="act-btn" onclick="openEditModal('${u.id}', '${(u.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}', '${(u.avatar_url||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')" style="color:var(--neon-cyan)">Edit</button>
                ${u.is_banned 
                    ? `<button class="act-btn" onclick="toggleBan('${u.id}', false, '${(u.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')">Unban</button>`
                    : `<button class="act-btn red" onclick="openBanModal('${u.id}', '${(u.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')">Ban</button>`
                }
                <button class="act-btn red" onclick="deleteUser('${u.id}', '${(u.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')" style="color:var(--neon-pink);border:1px solid var(--neon-pink)">Del</button>
            </div>`;
        } else {
            actionBlock = `<span style="color:var(--text-muted); font-size:11px;">Restricted</span>`;
        }

        return `<tr id="row-${u.id}">
            <td><div style="display:flex;align-items:center;gap:12px;">${av}<strong style="color:white;">${u.username||'Unknown'}</strong></div></td>
            <td><span style="font-size:11px;color:var(--text-muted);display:block;">${u.email||'—'}</span><span class="badge-tag ${roleStyle}" style="margin-top:4px;display:inline-block;">${(u.role||'user').toUpperCase()}</span></td>
            <td>${fmtDate(u.created_at)}</td>
            <td style="min-width:110px;">${timeCell}</td>
            <td>${status}</td>
            <td>
                ${actionBlock}
            </td>
        </tr>`;
    }).join('');
    updateTimers();
}

async function updateTimers() {
    const now = new Date().getTime();
    for (let u of allUsers) {
        if(!u.account_expires_at) continue;
        let el = document.getElementById(`timer-${u.id}`);
        if(!el) continue;
        
        let diff = new Date(u.account_expires_at).getTime() - now;
        if (diff <= 0) {
            el.innerHTML = "EXPIRED"; el.style.color = "var(--neon-pink)";
            delete u.account_expires_at;
            await autoDeleteUser(u.id, u.username);
            continue;
        }
        let d = Math.floor(diff / (1000*60*60*24)), h = Math.floor((diff % (1000*60*60*24))/(1000*60*60)), m = Math.floor((diff % (1000*60*60))/(1000*60)), s = Math.floor((diff % (1000*60))/1000);
        
        if (d > 7) { el.style.color = "#10b981"; el.style.textShadow = "0 0 5px rgba(16,185,129,0.5)"; }
        else if (d > 0 || h > 12) { el.style.color = "#f59e0b"; el.style.textShadow = "0 0 5px rgba(245,158,11,0.5)"; }
        else { el.style.color = "var(--neon-pink)"; el.style.textShadow = "0 0 5px rgba(255,51,153,0.5)"; }
        el.innerHTML = `${d}D : ${h.toString().padStart(2,'0')}H : ${m.toString().padStart(2,'0')}M : ${s.toString().padStart(2,'0')}S`;
    }
}

async function autoDeleteUser(uid, username) {
    try {
        const db = getSupabase();
        const { error } = await db.auth.admin.deleteUser(uid);
        if(!error) {
            logAdminAction('Deleted user', username + ' (Auto Expired)');
            const row = document.getElementById(`row-${uid}`);
            if(row) row.remove();
        }
    } catch(e) {}
}

async function deleteUser(uid, username) {
    if(!confirm("Are you sure you want to permanently DELETE this user?")) return;
    try {
        const db = getSupabase();
        const { error } = await db.auth.admin.deleteUser(uid);
        if(!error) {
            logAdminAction('Deleted user', username);
            toast('User Permanently Deleted.');
            loadUsers();
        } else { toast(error.message, true); }
    } catch(e) { toast(e.message, true); }
}

// Edit Modal
let currentEditId = null;
function openEditModal(id, username, avatar) {
    currentEditId = id; document.getElementById('editUsername').value = username; document.getElementById('editAvatarUrl').value = avatar; document.getElementById('editModal').classList.add('active');
}
function closeEditModal() { currentEditId = null; document.getElementById('editModal').classList.remove('active'); }
async function confirmEdit() {
    if(!currentEditId) return;
    const n = document.getElementById('editUsername').value, a = document.getElementById('editAvatarUrl').value;
    try {
        const db = getSupabase();
        const { error } = await db.from('profiles').update({ username: n, avatar_url: a }).eq('id', currentEditId);
        if(!error) {
            logAdminAction('Edited user', n);
            toast('Profile Updated.'); closeEditModal();
        } else toast(error.message, true);
    } catch(e) { toast(e.message, true); }
}

// Ban Modal
let currentBanId = null; let currentBanName = '';
function openBanModal(id, username) { currentBanId = id; currentBanName = username; document.getElementById('banModal').classList.add('active'); }
function closeBanModal() { currentBanId = null; document.getElementById('banModal').classList.remove('active'); }
async function toggleBan(id, isBanned, username) {
    const db = getSupabase();
    const { error } = await db.from('profiles').update({ is_banned: isBanned, ban_reason: null, ban_expires_at: null }).eq('id', id);
    if (!error) { 
        logAdminAction(isBanned ? 'Banned user' : 'Unbanned user', username);
        toast('Action Executed'); 
    } else toast(error.message, true);
}
async function confirmBan() {
    if (!currentBanId) return;
    const r = document.getElementById('banReason').value, d = parseInt(document.getElementById('banDays').value)||0, h = parseInt(document.getElementById('banHours').value)||0;
    let exp = null; if (d>0 || h>0) { let dt = new Date(); dt.setDate(dt.getDate()+d); dt.setHours(dt.getHours()+h); exp = dt.toISOString(); }
    const db = getSupabase();
    const { error } = await db.from('profiles').update({ is_banned: true, ban_reason: r, ban_expires_at: exp }).eq('id', currentBanId);
    if (!error) { 
        logAdminAction('Banned user', currentBanName);
        toast('User Protocol Terminated'); closeBanModal(); 
    } else toast(error.message, true);
}


// ==============================================================
// PAGE: REPORTS
// ==============================================================
async function loadReports() {
    const tb = document.getElementById('reportsTableBody');
    tb.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">Decoupling sub-reports...</td></tr>';
    try {
        const db = getSupabase();
        const filter = document.getElementById('reportFilter').value;
        let query = db.from('admin_reports_view').select('*').order('created_at', { ascending: false });
        if (filter) query = query.eq('status', filter);
        const { data, error } = await query;
        if (error) return tb.innerHTML = `<tr><td colspan="6" style="color:var(--neon-pink)">SQL Error: ${error.message}</td></tr>`;
        if (!data.length) return tb.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">No reports registered.</td></tr>';
        
        tb.innerHTML = data.map(r => {
            let statHtml = r.status==='resolved' ? '<span class="badge-tag t-cyan">RESOLVED</span>' : '<span class="badge-tag t-red">PENDING P1</span>';
            let desc = (r.description||'').length>45 ? r.description.substring(0,45)+'...' : r.description;
            let repMark = r.admin_reply ? '<br><span style="color:var(--neon-cyan);font-size:10px;">► SYSTEM RESPONSE ISSUED</span>' : '';
            return `<tr><td><strong style="color:#fff;">${r.username||'User'}</strong></td><td><span class="badge-tag t-purple">${(r.category||'GENERAL').toUpperCase()}</span></td><td>${desc}${repMark}</td><td>${fmtDate(r.created_at)}</td><td>${statHtml}</td><td><button class="act-btn" onclick="openReplyModal('${r.id}', '${r.user_id}', '${(r.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}', '${(r.description||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}', '${(r.admin_reply||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')">Investigate</button></td></tr>`;
        }).join('');
    } catch(e) {}
}

let currentRepId = null; let currentRepUserId = null; let currentRepUserStr = '';
function openReplyModal(id, uid, user, desc, prev) {
    currentRepId = id; currentRepUserId = uid; currentRepUserStr = user;
    document.getElementById('reportContext').innerHTML = `<strong style="color:#fff;">SOURCE:</strong> ${user}<br><br><strong style="color:#fff;">RAW PAYLOAD:</strong><br>${desc}`;
    document.getElementById('replyText').value = prev || '';
    document.getElementById('replyModal').classList.add('active');
}
function closeReplyModal() { currentRepId = null; document.getElementById('replyModal').classList.remove('active'); }

async function sendReply() {
    if (!currentRepId) return;
    const txt = document.getElementById('replyText').value.trim();
    if (!txt) return toast('Payload empty. Aborting.', true);
    const SEND_AS = '00000000-0000-0000-0000-000000000001'; 
    try {
        const db = getSupabase();
        await db.from('reports').update({ status: 'resolved', admin_reply: txt, replied_at: new Date().toISOString() }).eq('id', currentRepId);
        if (currentRepUserId) await db.from('messages').insert({ sender_id: SEND_AS, receiver_id: currentRepUserId, content: 'SYSTEM SUPPORT OVERRIDE: ' + txt });
        
        logAdminAction('Replied to report', `Report from ${currentRepUserStr}`);
        toast('Payload Transmitted Successfully.');
        closeReplyModal(); 
    } catch (e) { toast(e.message, true); }
}


// ==============================================================
// PAGE: ADMIN MANAGEMENT
// ==============================================================
async function createAdminAccount() {
    const name = document.getElementById('caName').value;
    const pass = document.getElementById('caPass').value;
    const pts = parseInt(document.getElementById('caPoints').value) || 0;

    const customPerms = {
        view_users: document.getElementById('permViewUsers').checked,
        view_reports: document.getElementById('permViewReports').checked,
        create_users: document.getElementById('permCreateUsers').checked,
        edit_ban: document.getElementById('permEditBan').checked
    };

    const safeUser = updateEmailPreview(name);
    if (!safeUser || !pass) return toast('Requires Username and Password', true);
    if (pass.length < 6) return toast('Password min 6 chars', true);
    const email = `${safeUser}@gopremium.com`;

    try {
        const db = getSupabase();
        const { data, error } = await db.auth.signUp({
            email, password: pass,
            options: { data: { username: safeUser, role: 'admin' } }
        });
        if (error) throw error;

        setTimeout(async () => {
            if (data?.user?.id) {
                await db.from('profiles').update({ 
                    username: safeUser,
                    email: email,
                    role: 'admin', 
                    points: pts, 
                    is_banned: false 
                }).eq('id', data.user.id);

                // Insert into admin_users so they can login to the website!
                await db.rpc('add_dashboard_access', { p_email: email, p_password: pass, p_username: safeUser, p_permissions: customPerms });

                logAdminAction('Created user', `Admin: ${safeUser}`);
                loadAdmins();
            }
        }, 1500);

        toast('Sub-Admin Deployed successfully.');
        document.getElementById('caName').value = '';
        document.getElementById('caPass').value = '';
    } catch(e) { toast(e.message, true); }
}

let loadedAdmins = [];

async function loadAdmins() {
    const tb = document.getElementById('adminsTableBody');
    tb.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--text-muted);">Syncing admins...</td></tr>';
    try {
        const db = getSupabase();
        const { data, error } = await db.from('profiles').select('*').in('role', ['admin', 'super_admin']).order('created_at', { ascending: false });
        if (error) return tb.innerHTML = `<tr><td colspan="5" style="color:var(--neon-pink)">Error: ${error.message}</td></tr>`;
        
        loadedAdmins = data || [];
        if (!loadedAdmins.length) return tb.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--text-muted);">No administrators located.</td></tr>';
        
        tb.innerHTML = loadedAdmins.map(u => {
            let roleStyle = u.role==='super_admin' ? 't-pink' : 't-purple';
            let ptCell = u.role==='super_admin' ? '<span style="color:var(--neon-pink); font-weight:bold;">Infinite (∞)</span>' : `<span style="color:var(--neon-cyan); font-weight:bold;">${u.points || 0}</span>`;
            
            // Only show points edit if it's a normal admin, or if super admin (but maybe protect super admins from normal admins tweaking them)
            let actionBtn = u.role==='super_admin' ? `<span style="color:var(--text-muted)">Protected Node</span>` : `<button class="act-btn" style="color:var(--neon-cyan);" onclick="openPointsModal('${u.id}', '${(u.username||'').replace(/'/g,"\\'").replace(/"/g,'&quot;')}')">Modify Points</button>`;

            return `<tr>
                <td><strong style="color:#fff;">${u.username||'Unknown Admin'}</strong></td>
                <td><span style="font-size:11px;color:var(--text-muted);display:block;">${u.email||'—'}</span></td>
                <td><span class="badge-tag ${roleStyle}">${(u.role||'ADMIN').toUpperCase()}</span></td>
                <td>${ptCell}</td>
                <td>${actionBtn}</td>
            </tr>`;
        }).join('');
    } catch(e) { tb.innerHTML = `<tr><td colspan="5" style="color:var(--neon-pink)">Init Error: ${e.message}</td></tr>`; }
}

// Points Validation
let currentPtAdminId = null; let currentPtAdminName = '';
function openPointsModal(id, name) {
    currentPtAdminId = id; currentPtAdminName = name;
    document.getElementById('ptAdminName').textContent = name;
    document.getElementById('ptDelta').value = 0;
    document.getElementById('pointsModal').classList.add('active');
}
function closePointsModal() { currentPtAdminId = null; document.getElementById('pointsModal').classList.remove('active'); }
async function confirmPointsUpdate() {
    if (!currentPtAdminId) return;
    const delta = parseInt(document.getElementById('ptDelta').value);
    if (isNaN(delta) || delta === 0) { toast("Delta must be a non-zero integer.", true); return; }

    try {
        const db = getSupabase();
        let targetPts = delta;
        if (targetPts < 0) targetPts = 0;

        const { error } = await db.from('profiles').update({ points: targetPts }).eq('id', currentPtAdminId);
        if (!error) {
            logAdminAction('Edited user', `Points adjusted for ${currentPtAdminName} by ${delta}`);
            toast('Points Transferred.');
            closePointsModal();
        } else { toast(error.message, true); }
    } catch(e) { toast(e.message, true); }
}

// Activity Logs
let allLogs = [];
async function loadLogs() {
    const tb = document.getElementById('logsTableBody');
    tb.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:20px;color:var(--text-muted);">Syncing logs...</td></tr>';
    try {
        const db = getSupabase();
        const filterAction = document.getElementById('logActionFilter').value;
        let query = db.from('admin_logs').select('*').order('created_at', { ascending: false }).limit(200);
        
        if (filterAction) query = query.eq('action_type', filterAction);

        const { data, error } = await query;
        if (error) {
            tb.innerHTML = `<tr><td colspan="4" style="color:var(--neon-pink)">SQL Error: ${error.message} (Did you run the setup script?)</td></tr>`;
            return;
        }
        allLogs = data || [];
        renderLogs(allLogs);
    } catch(e) { tb.innerHTML = `<tr><td colspan="4" style="color:var(--neon-pink)">Init Error: ${e.message}</td></tr>`; }
}

function filterLogs(val) {
    const q = val.toLowerCase();
    renderLogs(allLogs.filter(l => (l.admin_name||'').toLowerCase().includes(q) || (l.target||'').toLowerCase().includes(q)));
}

function renderLogs(logs) {
    const tb = document.getElementById('logsTableBody');
    if (!logs.length) return tb.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:20px;color:var(--text-muted);">No activity logged.</td></tr>';
    
    tb.innerHTML = logs.map(l => {
        let actionStyle = 'color:var(--neon-cyan)';
        if(l.action_type.includes('Created')) actionStyle = 'color:#10b981';
        if(l.action_type.includes('Deleted') || l.action_type.includes('Banned')) actionStyle = 'color:var(--neon-pink)';

        return `<tr>
            <td style="font-size:11px;color:var(--text-muted);">${fmtDate(l.created_at)}</td>
            <td><strong style="color:#fff;">${l.admin_name}</strong></td>
            <td><span style="font-weight:600; ${actionStyle}">${l.action_type}</span></td>
            <td><span style="color:var(--text-muted)">${l.target||'—'}</span></td>
        </tr>`;
    }).join('');
}
