import { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { ChatHeader } from "@/components/ChatHeader";
import { ChatMessage, Message } from "@/components/ChatMessage";
import { ChatInput } from "@/components/ChatInput";
import { WelcomeScreen } from "@/components/WelcomeScreen";
import { LoginDialog } from "@/components/LoginDialog";
import { ChatHistoryDialog } from "@/components/ChatHistoryDialog";
import { useToast } from "@/hooks/use-toast";
import { ensureMsalInitialized, accountToUser, msal } from "@/lib/auth/msal";

interface User {
  name: string;
  email: string;
  avatar: string;
}

type ChatSummary = {
  id: string;
  title: string;
  preview: string;
  messageCount: number;
  updatedAt: string; // ISO
};

// Point to your Node backend. Use .env (VITE_API_BASE) in prod.
const API_BASE = import.meta.env.VITE_API_BASE || "http://localhost:8080";

// -------- session helpers (frontend-only cache) --------
const makeSessionId = () =>
  `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;

const loadMessages = (sid: string): Message[] => {
  const key = `chat:${sid}`;
  try {
    const raw = sessionStorage.getItem(key);
    return raw ? (JSON.parse(raw) as Message[]) : [];
  } catch {
    return [];
  }
};

const saveMessagesLocal = (sid: string, msgs: Message[]) => {
  const key = `chat:${sid}`;
  sessionStorage.setItem(key, JSON.stringify(msgs));
  sessionStorage.setItem("sessionId", sid);
};
// ------------------------------------------------------

const Index = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [shareLoading, setShareLoading] = useState(false);

  // auth
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState<User | undefined>();

  // dialogs
  const [showLoginDialog, setShowLoginDialog] = useState(false);
  const [showHistoryDialog, setShowHistoryDialog] = useState(false);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);

  const [authReady, setAuthReady] = useState(false);

  // session
  const [sessionId, setSessionId] = useState<string>(() => {
    const saved = sessionStorage.getItem("sessionId");
    return saved || makeSessionId();
  });

  // dynamic history (from SQL)
  const [historyItems, setHistoryItems] = useState<ChatSummary[]>([]);

  const scrollRef = useRef<HTMLDivElement | null>(null);
  const lastSavedRef = useRef<string>(""); // payload hash to avoid redundant saves
  const shareOnceRef = useRef(false);  
  const { toast } = useToast();

  // === UTIL ===
  const userId = user?.email || "web-user";

  const serializableMessages = useMemo(() => {
    return messages.map((m) => ({
      ...m,
      timestamp:
        (m.timestamp as any)?.toISOString?.() ??
        (typeof m.timestamp === "string" ? m.timestamp : new Date().toISOString()),
    }));
  }, [messages]);

  const toSerializable = useCallback((msgs: Message[]) => {
    return msgs.map((m) => ({
      ...m,
      timestamp:
        (m.timestamp as any)?.toISOString?.() ??
        (typeof m.timestamp === "string" ? m.timestamp : new Date().toISOString()),
    }));
  }, []);

  const hashPayload = (obj: unknown) => {
    try {
      return JSON.stringify(obj);
    } catch {
      return "";
    }
  };

  // ======= Restore MSAL session on mount =======
  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        await ensureMsalInitialized();
        const acc = msal.getActiveAccount() ?? msal.getAllAccounts()[0] ?? null;
        if (!acc) return;
        const u = accountToUser(acc);
        if (!u || !mounted) return;
        setUser(u);
        setIsLoggedIn(true);
        console.log("[AUTH] Restored MSAL session for:", u.email);
      } catch {
        console.log("[AUTH] No active MSAL session");
      } finally {
        if (mounted) setAuthReady(true); // <-- important
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  // Load cached messages when sessionId changes
  useEffect(() => {
    const cached = loadMessages(sessionId);
    if (cached.length > 0) {
      setMessages(cached);
    } else {
      // keep empty; shared-load path sets messages explicitly
    }
  }, [sessionId]);

  useEffect(() => {
    if (isLoggedIn && showLoginDialog) setShowLoginDialog(false);
  }, [isLoggedIn, showLoginDialog]);

  // Persist messages per session + autoscroll
  useEffect(() => {
    saveMessagesLocal(sessionId, messages);
    scrollRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [messages, sessionId]);

  // ======= BACKEND: Save current chat to SQL (now supports overrides) =======
  const saveCurrentChat = useCallback(
    async (
      reason: string,
      msgsOverride?: Message[],
      sessionOverride?: string
    ) => {
      if (!isLoggedIn || !userId) return;

      const sid = sessionOverride ?? sessionId;
      const msgs = toSerializable(msgsOverride ?? messages);
      if (msgs.length === 0) return;

      const payload = { userId, sessionId: sid, messages: msgs };
      const h = hashPayload(payload);
      if (h === lastSavedRef.current) return;

      try {
        console.log(`[HISTORY] Saving chat (${reason})...`, {
          sessionId: sid,
          count: msgs.length,
        });
        const res = await fetch(`${API_BASE}/api/chats/save`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
          keepalive: true,
        });
        const data = await res.json();
        if (data.ok) {
          lastSavedRef.current = h;
          console.log(`[HISTORY] Saved chat id=${data.id}`);
        } else {
          console.warn("[HISTORY] Save failed:", data.error);
        }
      } catch (e) {
        console.warn("[HISTORY] Save error:", e);
      }
    },
    [API_BASE, isLoggedIn, userId, sessionId, messages, toSerializable]
  );

  // ======= Beacon save on close/refresh (shows browser confirm) =======
  useEffect(() => {
    const onBeforeUnload = (e: BeforeUnloadEvent) => {
      if (!isLoggedIn || serializableMessages.length === 0) return;
      e.preventDefault();
      e.returnValue = "";
    };
    const onPageHide = () => {
      if (!isLoggedIn || serializableMessages.length === 0) return;
      try {
        const blob = new Blob(
          [JSON.stringify({ userId, sessionId, messages: serializableMessages })],
          { type: "application/json" }
        );
        const sent = navigator.sendBeacon(`${API_BASE}/api/chats/save`, blob);
        console.log("[HISTORY] sendBeacon on pagehide:", sent);
      } catch (e) {
        console.log("[HISTORY] sendBeacon failed:", e);
      }
    };
    window.addEventListener("beforeunload", onBeforeUnload);
    window.addEventListener("pagehide", onPageHide);
    return () => {
      window.removeEventListener("beforeunload", onBeforeUnload);
      window.removeEventListener("pagehide", onPageHide);
    };
  }, [API_BASE, isLoggedIn, userId, sessionId, serializableMessages]);

  // ---- helpers to push messages into UI ----
  const pushUser = useCallback((content: string) => {
    const m: Message = {
      id: crypto.randomUUID(),
      content,
      role: "user",
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, m]);
    return m;
  }, []);

  const pushAssistant = useCallback((content: string) => {
    const m: Message = {
      id: crypto.randomUUID(),
      content,
      role: "assistant",
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, m]);
    return m;
  }, []);

  // ---- start a brand new chat (new session) ----
  const handleNewChat = useCallback(async () => {
    const old = sessionId;

    // Save current before clearing
    await saveCurrentChat("new-chat-click");

    const next = makeSessionId();
    setMessages([]);
    setSessionId(next);
    lastSavedRef.current = "";

    // Optional: clear server-side memory for old session
    try {
      await fetch(`${API_BASE}/api/chat/clear`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, sessionId: old }),
      });
    } catch {
      /* ignore */
    }

    toast({
      title: "New chat started",
      description: "Previous conversation saved and cleared",
    });
  }, [API_BASE, sessionId, userId, saveCurrentChat, toast]);

  // ---- main send handler ----
  // ---- main send handler ----
const handleSendMessage = async (message: string) => {
  if (!isLoggedIn) {
    setShowLoginDialog(true);
    return;
  }

  const text = (message || "").trim();
  if (!text) return;

  // 1) show user message instantly
  pushUser(text);
  setIsGenerating(true);

  try {
    console.log("[FRONTEND] sending to backend:", { text, sessionId, userId });

    const resp = await fetch(`${API_BASE}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: text, userId, sessionId }),
    });

    const data = await resp.json().catch(() => ({} as any));

    if (!resp.ok || data?.ok === false) {
      console.error("[FRONTEND] backend error (non-OK):", data);
      const contentFilter =
        data?.error_code === "content_filter" ||
        /content[_\s-]?filter/i.test(data?.error_message || "");

      const fallback = contentFilter
        ? "I’m unable to assist you with that request due to safety guidelines. I can help with safer, educational alternatives."
        : data?.error_message ||
          data?.detail?.error?.message ||
          "I couldn’t answer that right now. Please try a different question.";

      pushAssistant(fallback);
      setIsGenerating(false); // hide spinner immediately on error
      return;
    }

    const replyText =
      data?.reply ||
      "I couldn’t produce a response. Please try asking in a different way.";
    pushAssistant(replyText);

    // ✅ Hide spinner right away (don’t wait for save)
    setIsGenerating(false);

    // ✅ Fire-and-forget save; no UI delay
    void saveCurrentChat("auto-after-reply");
  } catch (e: any) {
    console.error("[FRONTEND] fetch failed:", e);
    pushAssistant("Network issue. Please check your connection and try again.");
    setIsGenerating(false); // also hide on catch
  }
};


  // auth callbacks
  const handleLogin = (userData: User) => {
    setUser(userData);
    setIsLoggedIn(true);
    toast({
      title: "Welcome back!",
      description: `Signed in as ${userData.name}`,
    });
  };

  const handleLogout = () => {
    setUser(undefined);
    setIsLoggedIn(false);
    setMessages([]);
    const next = makeSessionId();
    setSessionId(next);
    lastSavedRef.current = "";
    toast({
      title: "Signed out",
      description: "You have been successfully signed out",
    });
  };

  // ======= HISTORY =======
  const handleShowHistory = async () => {
    if (!isLoggedIn) {
      setShowLoginDialog(true);
      return;
    }
    setIsHistoryLoading(true);
    try {
      console.log("[HISTORY] Fetching chat list...");
      const res = await fetch(
        `${API_BASE}/api/chats?userId=${encodeURIComponent(userId)}`
      );
      const data = await res.json();
      if (data.ok) {
        setHistoryItems(data.items || []);
        console.log(`[HISTORY] Loaded ${data.items?.length ?? 0} items`);
      } else {
        console.warn("[HISTORY] List failed:", data.error);
      }
    } catch (e) {
      console.warn("[HISTORY] List error:", e);
    } finally {
      setIsHistoryLoading(false);
      setShowHistoryDialog(true);
    }
  };

  const handleSelectChat = async (chatId: string) => {
    try {
      console.log(`[HISTORY] Fetching chat ${chatId}...`);
      const res = await fetch(
        `${API_BASE}/api/chats/${chatId}?userId=${encodeURIComponent(userId)}`
      );
      const data = await res.json();
      if (data.ok) {
        const stored = JSON.parse(data.chat.messages || "[]");
        const mapped: Message[] = stored.map((m: any) => ({
          id: m.id || crypto.randomUUID(),
          content: m.content,
          role: m.role,
          timestamp: m.timestamp ? new Date(m.timestamp) : new Date(),
        }));
        setSessionId(data.chat.sessionId);
        setMessages(mapped);

        saveMessagesLocal(data.chat.sessionId, mapped);
        lastSavedRef.current = hashPayload({
          userId,
          sessionId: data.chat.sessionId,
          messages: stored,
        });
        toast({
          title: "Chat loaded",
          description: data.chat.title || "Previous chat",
        });
      } else {
        toast({
          title: "Unable to load chat",
          description: "Please try again",
          variant: "destructive" as any,
        });
      }
    } catch (e) {
      console.warn("[HISTORY] Get error:", e);
      toast({
        title: "Unable to load chat",
        description: "Please try again",
        variant: "destructive" as any,
      });
    }
  };

  // ======= SHARE (creates link) =======
  const handleShare = useCallback(async () => {
    if (!isLoggedIn) {
      setShowLoginDialog(true);
      return;
    }
    setShareLoading(true);
    // Ensure latest content is saved before creating link
    await saveCurrentChat("share-click");

    try {
      const resp = await fetch(`${API_BASE}/api/chats/share-link`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, sessionId }),
      });
      const data = await resp.json();
      if (!data.ok) throw new Error(data.error || "share_link_failed");

      const token = data.token as string;
      const link = `${window.location.origin}/?share=${encodeURIComponent(token)}`;
      await navigator.clipboard.writeText(link);

      toast({
        title: "Share link copied",
        description: link,
      });
      console.log("[SHARE] link:", link);
    } catch (e: any) {
      toast({
        title: "Share failed",
        description: e?.message || "Please try again",
        variant: "destructive" as any,
      });
    } finally {
      setShareLoading(false);
    }
  }, [API_BASE, isLoggedIn, saveCurrentChat, userId, sessionId, toast]);

  // ======= OPEN chat via shared link (FIXED: persist immediately before chatting) =======
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const token = params.get("share");
    if (!token) return;
    if (!authReady) return; // wait until MSAL restore finished

    if (!isLoggedIn) {
      setShowLoginDialog(true);
      return;
    }

  if (shareOnceRef.current) return;
  shareOnceRef.current = true;

    (async () => {
      try {
        console.log("[SHARE] Resolving token:", token);
        const resp = await fetch(`${API_BASE}/api/share/${encodeURIComponent(token)}`);
        const data = await resp.json();
        if (!data.ok) throw new Error(data.error || "invalid_share_token");

        const stored = JSON.parse(data.chat.messages || "[]");
        const mapped: Message[] = stored.map((m: any) => ({
          id: m.id || crypto.randomUUID(),
          content: m.content,
          role: m.role,
          timestamp: m.timestamp ? new Date(m.timestamp) : new Date(),
        }));

        const newSid = makeSessionId();
        setSessionId(newSid);
        setMessages(mapped);
        lastSavedRef.current = "";
        saveMessagesLocal(newSid, mapped);

        // *** Critical fix: persist imported history immediately so /api/chat hydrates it ***
        await saveCurrentChat("import-share", mapped, newSid);

        toast({ title: "Shared chat loaded", description: `From: ${data.ownerUserId}`, duration: 1500 });

        // Clean URL
        window.history.replaceState({}, document.title, window.location.pathname);
      } catch (e: any) {
        toast({
          title: "Unable to open shared chat",
          description: e?.message || "Please try again",
          variant: "destructive" as any,
        });
      }
    })();
  }, [API_BASE, authReady, isLoggedIn, saveCurrentChat, toast]);

  const handleStopGenerating = () => {
    setIsGenerating(false);
    toast({
      title: "Generation stopped",
      description: "AI response was interrupted",
    });
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <ChatHeader
        isLoggedIn={isLoggedIn}
        user={user}
        onLogin={() => setShowLoginDialog(true)}
        onLogout={handleLogout}
        onShowHistory={handleShowHistory}
        historyLoading={isHistoryLoading}
        onShare={handleShare}
        shareLoading={shareLoading}
      />

      <LoginDialog
        open={showLoginDialog}
        onOpenChange={setShowLoginDialog}
        onLogin={handleLogin}
      />

      <ChatHistoryDialog
        open={showHistoryDialog}
        onOpenChange={setShowHistoryDialog}
        onSelectChat={handleSelectChat}
        // @ts-ignore — component accepts this in the updated version
        chats={historyItems}
      />

      <div className="flex-1 flex flex-col">
        {messages.length === 0 ? (
          <WelcomeScreen />
        ) : (
          <div className="flex-1 overflow-y-auto">
            <div className="max-w-4xl mx-auto">
              {messages.map((message) => (
                <ChatMessage key={message.id} message={message} />
              ))}

              {isGenerating && (
                <div className="flex gap-4 p-4">
                  <div className="flex-shrink-0">
                    <div className="w-8 h-8 bg-logo-primary rounded-full animate-pulse"></div>
                  </div>
                  <div className="bg-chat-bubble-ai border border-border rounded-2xl px-4 py-3 mr-12">
                    <div className="text-sm text-muted-foreground">
                      Thinking...
                    </div>
                  </div>
                </div>
              )}
              <div ref={scrollRef} />
            </div>
          </div>
        )}

        <div className="border-t border-border bg-background">
          <ChatInput
            onSendMessage={handleSendMessage}
            isGenerating={isGenerating}
            onStopGenerating={handleStopGenerating}
            onNewChat={messages.length > 0 ? handleNewChat : undefined}
            disabled={isGenerating}
          />
          <div className="mx-auto max-w-4xl px-4 py-2">
            <p className="text-center text-xs text-muted-foreground">
              Session: {sessionId}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Index;
