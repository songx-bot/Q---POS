import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";

export type ToastKind = "success" | "error" | "warning" | "info";
export type ToastAction = { label: string; onClick: () => void };
export type ToastMessage = { kind: ToastKind; message: string; action?: ToastAction };

type ToastEntry = ToastMessage & { id: number };
const ToastContext = createContext<(message: ToastMessage) => void>(() => undefined);
let nextToastId = 0;

export function useToast() {
  return useContext(ToastContext);
}

function ToastCard({ toast, dismiss }: { toast: ToastEntry; dismiss: (id: number) => void }) {
  useEffect(() => {
    const timeout = window.setTimeout(() => dismiss(toast.id), toast.action ? 9000 : 5500);
    return () => window.clearTimeout(timeout);
  }, [dismiss, toast.action, toast.id]);

  return (
    <div className={`toast-card is-${toast.kind}`} role={toast.kind === "success" || toast.kind === "info" ? "status" : "alert"}>
      <span className="toast-symbol" aria-hidden="true">{toast.kind === "success" ? "✓" : toast.kind === "warning" ? "!" : toast.kind === "error" ? "×" : "i"}</span>
      <p>{toast.message}</p>
      {toast.action && <button type="button" className="toast-action" onClick={() => { dismiss(toast.id); toast.action?.onClick(); }}>{toast.action.label}</button>}
      <button type="button" className="toast-dismiss" onClick={() => dismiss(toast.id)} aria-label="Dismiss notification">×</button>
    </div>
  );
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastEntry[]>([]);
  const showToast = useCallback((message: ToastMessage) => {
    const id = ++nextToastId;
    setToasts((current) => [...current, { ...message, id }].slice(-5));
  }, []);
  const dismiss = useCallback((id: number) => setToasts((current) => current.filter((toast) => toast.id !== id)), []);

  return (
    <ToastContext.Provider value={showToast}>
      {children}
      <div className="toast-viewport" aria-label="Notifications" aria-live="off">
        {toasts.map((toast) => <ToastCard key={toast.id} toast={toast} dismiss={dismiss} />)}
      </div>
    </ToastContext.Provider>
  );
}
