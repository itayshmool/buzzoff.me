interface ConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmDialog({
  isOpen,
  title,
  message,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onCancel} />
      <div className="relative bg-surface-card border border-danger/30 p-6 max-w-sm w-full mx-4 clip-angular animate-fade-up">
        <h3 className="font-heading text-base font-bold tracking-wider text-danger text-glow-hot uppercase">
          {title}
        </h3>
        <p className="mt-3 text-sm text-text-secondary">{message}</p>
        <div className="mt-5 flex justify-end gap-3">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-sm font-heading tracking-wider text-text-muted border border-border hover:border-border-bright hover:text-text-primary transition-colors"
          >
            ABORT
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-2 text-sm font-heading tracking-wider bg-danger text-white hover:bg-danger-dim transition-colors"
          >
            CONFIRM
          </button>
        </div>
      </div>
    </div>
  );
}
