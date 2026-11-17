// ============================================================
// CONFIG – change the first two values (Lab 3.2)
// ============================================================
const CONFIG = {
    clientId:    "00000000-0000-0000-0000-000000000000",  // App registration -> Application (client) ID
    tenantId:    "00000000-0000-0000-0000-000000000000",  // Directory (tenant) ID, or "organizations"
    redirectUri: window.location.origin                   // must match the SPA redirect URI in Entra
};
const SCOPES = ["User.Read", "User.ReadWrite"];
const GRAPH  = "https://graph.microsoft.com/v1.0";
const SELECT = "displayName,userPrincipalName,jobTitle,department,mobilePhone";

// ============================================================
// UI refs
// ============================================================
const $ = id => document.getElementById(id);
const ui = {
    login: $("loginBtn"), logout: $("logoutBtn"), profile: $("profileBtn"),
    save: $("saveBtn"), jobTitle: $("jobTitleBtn"), token: $("tokenBtn"),
    copyToken: $("copyTokenBtn"), mobile: $("mobileInput"),
    status: $("status"), profileOut: $("profileOut"), tokenOut: $("tokenOut")
};

function show(el, content, cls) {
    el.textContent = typeof content === "string" ? content : JSON.stringify(content, null, 2);
    el.className = cls || "";
}
function fail(msg) {
    console.error(msg);
    show(ui.profileOut, String(msg), "err");
    ui.status.textContent = "Error – see the panel below and the browser console (F12).";
    ui.status.className = "err";
}

// Surface anything that would otherwise fail silently.
window.addEventListener("error", e => fail(`Script error: ${e.message}`));
window.addEventListener("unhandledrejection", e => fail(`Unhandled rejection: ${e.reason?.message || e.reason}`));

// ============================================================
// Preflight: catch the classic misconfigurations before MSAL does
// ============================================================
const PLACEHOLDER = "00000000-0000-0000-0000-000000000000";
const GUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function preflight() {
    if (!window.msal || !window.msal.PublicClientApplication)
        return "MSAL did not load. Check the <script> tag in index.html and your network access to alcdn.msauth.net.";
    if (location.protocol === "file:")
        return "This page was opened via file:// – MSAL requires http://localhost. Start a local web server (e.g. 'serve -l 3000').";
    if (CONFIG.clientId === PLACEHOLDER || CONFIG.tenantId === PLACEHOLDER)
        return "CONFIG still contains the placeholder GUIDs. Enter your Application (client) ID and Directory (tenant) ID at the top of app.js.";
    if (!GUID.test(CONFIG.clientId))
        return `clientId is not a valid GUID: "${CONFIG.clientId}"`;
    if (!GUID.test(CONFIG.tenantId) && !["common", "organizations", "consumers"].includes(CONFIG.tenantId))
        return `tenantId must be a GUID or one of common/organizations/consumers – got "${CONFIG.tenantId}"`;
    return null;
}

// ============================================================
// MSAL
// ============================================================
let msalInstance = null;
let account = null;

function setSignedIn(acc) {
    account = acc;
    const on = !!acc;
    [ui.logout, ui.profile, ui.save, ui.jobTitle, ui.token, ui.copyToken, ui.mobile]
        .forEach(el => el.disabled = !on);
    ui.login.disabled = on;
    ui.status.className = "";
    ui.status.textContent = on ? `Signed in as ${acc.username}` : "Not signed in.";
}

// Buttons stay disabled until MSAL has finished processing any redirect response.
// Clicking loginRedirect() before that resolves is what makes "nothing happen".
async function boot() {
    ui.login.disabled = true;
    ui.status.textContent = "Initialising…";

    const problem = preflight();
    if (problem) { fail(problem); return; }

    msalInstance = new msal.PublicClientApplication({
        auth: {
            clientId: CONFIG.clientId,
            authority: `https://login.microsoftonline.com/${CONFIG.tenantId}`,
            redirectUri: CONFIG.redirectUri
        },
        cache: { cacheLocation: "sessionStorage", storeAuthStateInCookie: false },
        system: {
            loggerOptions: {
                logLevel: msal.LogLevel.Warning,
                loggerCallback: (lvl, msg, pii) => { if (!pii) console.log("[MSAL]", msg); }
            }
        }
    });

    try {
        const resp = await msalInstance.handleRedirectPromise();
        setSignedIn(resp?.account ?? msalInstance.getAllAccounts()[0] ?? null);
        ui.login.disabled = !!account;
    } catch (e) {
        // A failed redirect can leave "interaction_in_progress" behind and block every later login.
        if (String(e.errorCode).includes("interaction_in_progress")) {
            sessionStorage.clear();
            fail("A previous sign-in was interrupted. Session storage has been cleared – click Sign in again.");
        } else {
            fail(`Redirect error: ${e.errorCode || ""} ${e.errorMessage || e.message}`);
        }
        ui.login.disabled = false;
    }
}

// ============================================================
// Token + Graph helpers
// ============================================================
async function getToken() {
    try {
        const r = await msalInstance.acquireTokenSilent({ scopes: SCOPES, account });
        return r.accessToken;
    } catch (e) {
        if (e instanceof msal.InteractionRequiredAuthError) {
            await msalInstance.acquireTokenRedirect({ scopes: SCOPES, account });
            return null;
        }
        throw e;
    }
}

async function graph(method, path, body) {
    const token = await getToken();
    if (!token) return null;
    const resp = await fetch(GRAPH + path, {
        method,
        headers: { Authorization: `Bearer ${token}`, ...(body && { "Content-Type": "application/json" }) },
        body: body ? JSON.stringify(body) : undefined
    });
    const text = await resp.text();
    let data = null;
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }
    return { status: resp.status, ok: resp.ok, data };
}

function decodeJwt(token) {
    const p = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    return JSON.parse(decodeURIComponent(escape(atob(p))));
}

// Wraps every handler so an error lands in the UI instead of the void.
const safe = fn => async () => { try { await fn(); } catch (e) { fail(e.errorMessage || e.message || e); } };

// ============================================================
// Handlers
// ============================================================
ui.login.onclick = safe(async () => {
    ui.status.textContent = "Redirecting to sign-in…";
    await msalInstance.loginRedirect({ scopes: SCOPES });
});

ui.logout.onclick = safe(() => msalInstance.logoutRedirect({ account }));

ui.profile.onclick = safe(async () => {
    const r = await graph("GET", `/me?$select=${SELECT}`);
    if (!r) return;
    if (r.ok) ui.mobile.value = r.data.mobilePhone || "";
    show(ui.profileOut, `HTTP ${r.status}\n` + JSON.stringify(r.data, null, 2), r.ok ? "" : "err");
});

ui.save.onclick = safe(async () => {
    const r = await graph("PATCH", "/me", { mobilePhone: ui.mobile.value || null });
    if (!r) return;
    if (r.status === 204) {
        const g = await graph("GET", `/me?$select=${SELECT}`);
        show(ui.profileOut, "PATCH -> HTTP 204 (No Content)\n\n" + JSON.stringify(g.data, null, 2), "ok");
    } else {
        show(ui.profileOut, `PATCH -> HTTP ${r.status}\n` + JSON.stringify(r.data, null, 2), "err");
    }
});

// Deliberate failure: User.ReadWrite (delegated) does not cover organizational attributes.
ui.jobTitle.onclick = safe(async () => {
    const r = await graph("PATCH", "/me", { jobTitle: "Chief Demo Officer" });
    if (!r) return;
    show(ui.profileOut,
        `PATCH jobTitle -> HTTP ${r.status}\n` + JSON.stringify(r.data, null, 2) +
        (r.status === 403 ? "\n\nExpected: jobTitle is an organizational attribute. Delegated rights are scope AND user rights." : ""),
        r.ok ? "ok" : "err");
});

ui.token.onclick = safe(async () => {
    const token = await getToken();
    if (!token) return;
    const c = decodeJwt(token);
    const lines = Object.entries(c).map(([k, v]) => {
        if (["iat", "nbf", "exp"].includes(k))
            v = `${v}  (${new Date(v * 1000).toLocaleString()})`;
        return `${k.padEnd(20)} ${typeof v === "object" ? JSON.stringify(v) : v}`;
    });
    show(ui.tokenOut, lines.join("\n"));
});

ui.copyToken.onclick = safe(async () => {
    const token = await getToken();
    if (!token) return;
    await navigator.clipboard.writeText(token);
    ui.status.textContent = "Token copied – paste it into https://jwt.ms";
});

boot();
