import { useMemo, useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Search, MessageSquare, Calendar } from "lucide-react";
import { ScrollArea } from "@/components/ui/scroll-area";

type ChatSummary = {
  id: string;
  title: string;
  preview: string;
  messageCount: number;
  updatedAt: string; // ISO string from server
};

interface ChatHistoryDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSelectChat: (chatId: string) => void;
  chats: ChatSummary[]; // <— now passed from parent
}

export const ChatHistoryDialog = ({ open, onOpenChange, onSelectChat, chats }: ChatHistoryDialogProps) => {
  const [searchQuery, setSearchQuery] = useState("");

  const filteredChats = useMemo(() => {
    const q = searchQuery.toLowerCase();
    return (chats || []).filter(chat =>
      (chat.title || "").toLowerCase().includes(q) ||
      (chat.preview || "").toLowerCase().includes(q)
    );
  }, [chats, searchQuery]);

  const handleSelectChat = (chatId: string) => {
    onSelectChat(chatId);
    onOpenChange(false);
  };

  const formatDate = (iso: string) => {
    const date = new Date(iso);
    const now = new Date();
    const diffInDays = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));
    if (diffInDays === 0) return "Today";
    if (diffInDays === 1) return "Yesterday";
    if (diffInDays < 7) return `${diffInDays} days ago`;
    return date.toLocaleDateString();
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg h-[600px] flex flex-col">
        <DialogHeader>
          <DialogTitle className="text-xl font-semibold">Chat History</DialogTitle>
        </DialogHeader>

        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Search your conversations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-9"
          />
        </div>

        <ScrollArea className="flex-1 -mx-6 px-6">
          <div className="space-y-2">
            {filteredChats.map((chat) => (
              <Button
                key={chat.id}
                variant="ghost"
                className="w-full p-4 h-auto justify-start text-left hover:bg-accent/50"
                onClick={() => handleSelectChat(chat.id)}
              >
                <div className="flex items-start gap-3 w-full">
                  <div className="p-2 bg-logo-primary/10 rounded-lg">
                    <MessageSquare className="w-4 h-4 text-logo-primary" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="font-medium text-sm truncate">{chat.title || "Untitled chat"}</h3>
                      <div className="flex items-center gap-1 text-xs text-muted-foreground ml-2">
                        <Calendar className="w-3 h-3" />
                        {formatDate(chat.updatedAt)}
                      </div>
                    </div>
                    <p className="text-xs text-muted-foreground line-clamp-2">
                      {chat.preview}
                    </p>
                    <div className="flex items-center gap-2 mt-2">
                      <span className="text-xs text-muted-foreground">
                        {chat.messageCount} messages
                      </span>
                    </div>
                  </div>
                </div>
              </Button>
            ))}

            {filteredChats.length === 0 && (
              <div className="text-center py-8">
                <MessageSquare className="w-12 h-12 text-muted-foreground/50 mx-auto mb-4" />
                <p className="text-muted-foreground">
                  {searchQuery ? "No chats found matching your search." : "No chat history yet."}
                </p>
              </div>
            )}
          </div>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
};
