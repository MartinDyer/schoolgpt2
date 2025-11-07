import { PublicClientApplication, AccountInfo } from "@azure/msal-browser";

const tenant = import.meta.env.VITE_AZURE_TENANT_ID || "organizations";

// Quick runtime check to help catch misplaced .env files (Vite loads env from project root)
if (!import.meta.env.VITE_AZURE_CLIENT_ID) {
  // eslint-disable-next-line no-console
  console.warn(
    "VITE_AZURE_CLIENT_ID is not set. Make sure your .env file is at the project root (not inside src/) and that VITE_ vars are prefixed correctly."
  );
}

export const msal = new PublicClientApplication({
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID,
    authority: `https://login.microsoftonline.com/${tenant}`,
    redirectUri: import.meta.env.VITE_AZURE_REDIRECT_URI || window.location.origin,
    postLogoutRedirectUri:
      import.meta.env.VITE_AZURE_POST_LOGOUT_REDIRECT_URI || window.location.origin,
  },
  cache: { cacheLocation: "localStorage", storeAuthStateInCookie: false },
});

/** single-shot initializer for MSAL v3+ (no-op on v2) */
let initPromise: Promise<void> | null = null;
export async function ensureMsalInitialized() {
  if ((msal as any).initialize) {
    if (!initPromise) {
      initPromise = (msal as any).initialize().then(() => {
        const acc = msal.getActiveAccount() ?? msal.getAllAccounts()[0] ?? null;
        if (acc) msal.setActiveAccount(acc);
      });
    }
    return initPromise;
  }
  // v2 fallback
  if (!initPromise) {
    initPromise = Promise.resolve().then(() => {
      const acc = msal.getActiveAccount() ?? msal.getAllAccounts()[0] ?? null;
      if (acc) msal.setActiveAccount(acc);
    });
  }
  return initPromise;
}

export async function signInWithMicrosoft() {
  await ensureMsalInitialized();
  const result = await msal.loginPopup({ scopes: ["User.Read"] });
  const account = result.account || msal.getAllAccounts()[0] || null;
  if (account) msal.setActiveAccount(account);
  return account;
}

/**
 * Acquire an access token for the requested scopes. This will first try a silent
 * acquisition and fall back to an interactive popup flow. Returns the access token string or null.
 */
export async function acquireToken(scopes: string[] = ["User.Read"]) {
  await ensureMsalInitialized();
  const account = msal.getActiveAccount() ?? msal.getAllAccounts()[0] ?? null;
  if (!account) {
    // No account present - trigger interactive sign-in which will also set active account
    try {
      await signInWithMicrosoft();
    } catch (e) {
      // interactive sign-in failed
      return null;
    }
  }

  try {
    const silent = await msal.acquireTokenSilent({ scopes, account: msal.getActiveAccount()! });
    return silent.accessToken;
  } catch (err) {
    // silent failed (consent/exp), try popup
    try {
      const popup = await msal.acquireTokenPopup({ scopes });
      return popup.accessToken;
    } catch (err2) {
      // as a last resort, prompt full login
      try {
        const res = await msal.loginPopup({ scopes });
        return res?.accessToken || null;
      } catch (err3) {
        return null;
      }
    }
  }
}

export async function signOutMicrosoft() {
  await ensureMsalInitialized();
  const account = msal.getActiveAccount() ?? msal.getAllAccounts()[0];
  try {
    await msal.logoutPopup({ account });
  } catch {
    await msal.logoutRedirect({ account });
  } finally {
    try {
      msal.setActiveAccount(null);
    } catch {}
  }
}

export function accountToUser(a: AccountInfo | null) {
  if (!a) return null;
  return {
    name: a.name || a.username,
    email: a.username,
    avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(
      a.name || a.username
    )}&background=fff&color=111`,
  };
}
