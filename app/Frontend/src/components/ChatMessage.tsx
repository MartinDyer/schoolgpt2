import { cn } from "@/lib/utils";
import { SchoolSafeAILogo } from "./SchoolSafeAILogo";
import { User } from "lucide-react";

export interface Message {
  id: string;
  content: string;
  role: "user" | "assistant";
  timestamp: Date;
}

interface ChatMessageProps {
  message: Message;
}

export const ChatMessage = ({ message }: ChatMessageProps) => {
  const isUser = message.role === "user";
  
  return (
    <div className={cn("flex gap-4 p-4", isUser ? "justify-end" : "justify-start")}>
      {!isUser && (
        <div className="flex-shrink-0">
          <SchoolSafeAILogo size="sm" />
        </div>
      )}
      
      <div className={cn(
        "max-w-3xl rounded-2xl px-4 py-3",
        isUser 
          ? "bg-chat-bubble-user text-chat-bubble-user-foreground ml-12" 
          : "bg-chat-bubble-ai text-chat-bubble-ai-foreground border border-border mr-12"
      )}>
        <div className="whitespace-pre-wrap text-sm leading-relaxed">
          {message.content}
        </div>
      </div>
      
      {isUser && (
        <div className="flex-shrink-0">
          <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center">
            <User className="w-4 h-4 text-primary-foreground" />
          </div>
        </div>
      )}
    </div>
  );
};