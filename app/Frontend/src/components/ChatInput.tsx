import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Send, Plus, Square } from "lucide-react";
import { cn } from "@/lib/utils";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";

interface ChatInputProps {
  onSendMessage: (message: string) => void;
  isGenerating?: boolean;
  onStopGenerating?: () => void;
  onNewChat?: () => void;
  disabled?: boolean;
}

export const ChatInput = ({ 
  onSendMessage, 
  isGenerating = false, 
  onStopGenerating,
  onNewChat,
  disabled = false 
}: ChatInputProps) => {
  const [message, setMessage] = useState("");
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [isConfirmLoading, setIsConfirmLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (message.trim() && !disabled && !isGenerating) {
      onSendMessage(message.trim());
      setMessage("");
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  return (
    <div className="w-full max-w-4xl mx-auto p-4">
      <div className="bg-chat-input-bg border border-border rounded-2xl shadow-sm">
        <div className="flex items-start gap-3 p-4">
          {onNewChat && (
            <>
              <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
                <div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setConfirmOpen(true)}
                    className="flex-shrink-0 mt-1"
                  >
                    <Plus className="w-4 h-4" />
                  </Button>

                  <DialogContent className="sm:max-w-sm">
                    <DialogHeader className="text-center">
                      <DialogTitle className="text-lg font-medium">Start a new chat?</DialogTitle>
                      <DialogDescription className="mt-1">
                        Starting a new chat will clear your current conversation in this session. Do you want to continue?
                      </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                      <Button variant="outline" size="sm" onClick={() => setConfirmOpen(false)}>
                        Cancel
                      </Button>
                      <Button
                        size="sm"
                        onClick={async () => {
                          try {
                            setIsConfirmLoading(true);
                            // Await user's onNewChat; if it returns a promise we await it
                            await (onNewChat as () => Promise<void>)();
                            setConfirmOpen(false);
                          } catch (e) {
                            console.error("New chat failed:", e);
                          } finally {
                            setIsConfirmLoading(false);
                          }
                        }}
                        disabled={isConfirmLoading}
                        className="flex items-center gap-2"
                      >
                        {isConfirmLoading ? (
                          <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                          </svg>
                        ) : null}
                        Yes
                      </Button>
                    </DialogFooter>
                  </DialogContent>
                </div>
              </Dialog>
            </>
          )}
          
          <form onSubmit={handleSubmit} className="flex-1 flex gap-3">
            <Textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Type a new question..."
              disabled={disabled}
              className={cn(
                "min-h-[44px] max-h-32 resize-none border-0 bg-transparent",
                "focus-visible:ring-0 focus-visible:ring-offset-0",
                "placeholder:text-muted-foreground"
              )}
            />
            
            {isGenerating ? (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={onStopGenerating}
                className="flex-shrink-0 mt-1"
              >
                <Square className="w-4 h-4" />
                Stop generating
              </Button>
            ) : (
              <Button
                type="submit"
                size="sm"
                disabled={!message.trim() || disabled}
                className="flex-shrink-0 mt-1"
              >
                <Send className="w-4 h-4" />
              </Button>
            )}
          </form>
        </div>
      </div>
    </div>
  );
};