import { Button } from "@/components/ui/button";
import { History, Share2, User, LogOut } from "lucide-react";
import { SchoolSafeAILogo } from "./SchoolSafeAILogo";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { signOutMicrosoft } from "@/lib/auth/msal";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

interface User {
  name: string;
  email: string;
  avatar: string;
}

interface ChatHeaderProps {
  isLoggedIn: boolean;
  user?: User;
  onLogin: () => void;
  onLogout: () => void;
  onShowHistory: () => void;
  historyLoading?: boolean;
  onShare: () => void;
  shareLoading?: boolean;
}

export const ChatHeader = ({ 
  isLoggedIn, 
  user, 
  onLogin, 
  onLogout, 
  onShowHistory, 
  historyLoading = false,
  onShare,
  shareLoading = false
}: ChatHeaderProps) => {
  return (
    <header className="w-full bg-header-bg border-b border-border px-4 sm:px-6 py-4">
      <div className="flex items-center justify-between max-w-7xl mx-auto">
        <div className="flex items-center gap-2 sm:gap-3">
          <SchoolSafeAILogo size="sm" />
          <h1 className="text-lg sm:text-xl font-semibold text-foreground">School-Safe-AI</h1>
        </div>
        
        <div className="flex items-center gap-1 sm:gap-3">
          {isLoggedIn ? (
            <>
              <Button 
                variant="outline" 
                size="sm"
                onClick={onShowHistory}
                disabled={historyLoading}
                className="hidden sm:flex items-center gap-2"
              >
                {historyLoading ? (
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                ) : (
                  <History className="w-4 h-4" />
                )}
                <span>{historyLoading ? "Loading..." : "Chat history"}</span>
              </Button>
              
              <Button 
                variant="outline"
                size="sm"
                onClick={onShowHistory}
                disabled={historyLoading}
                className="sm:hidden p-2"
              >
                {historyLoading ? (
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                ) : (
                  <History className="w-4 h-4" />
                )}
              </Button>
              
              <Button 
                variant="outline"
                size="sm"
                onClick={onShare}
                disabled={shareLoading}
                className="hidden sm:flex items-center gap-2"
              >
                {shareLoading ? (
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                ) : (
                  <Share2 className="w-4 h-4" />
                )}
                {shareLoading ? "Sharing..." : "Share"}
              </Button>

              <Button 
                variant="outline"
                size="sm"
                onClick={onShare}
                disabled={shareLoading}
                className="sm:hidden p-2"
              >
                {shareLoading ? (
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                  </svg>
                ) : (
                  <Share2 className="w-4 h-4" />
                )}
              </Button>

              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                    <Avatar className="h-8 w-8">
                      <AvatarImage src={user?.avatar} alt={user?.name} />
                      <AvatarFallback>
                        {user?.name?.split(' ').map(n => n[0]).join('').toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-56" align="end" forceMount>
                  <div className="flex items-center justify-start gap-2 p-2">
                    <div className="flex flex-col space-y-1 leading-none">
                      <p className="font-medium">{user?.name}</p>
                      <p className="text-xs text-muted-foreground">{user?.email}</p>
                    </div>
                  </div>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
  onClick={async () => {
    await signOutMicrosoft(); // clears Microsoft session + active account
    onLogout();               // your existing local cleanup/UI state
  }}
  className="text-red-600 focus:text-red-600"
>
  <LogOut className="mr-2 h-4 w-4" />
  Sign out
</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </>
          ) : (
            <Button onClick={onLogin} className="flex items-center gap-2 text-sm sm:text-base">
              <User className="w-4 h-4" />
              <span className="hidden sm:inline">Sign in</span>
            </Button>
          )}
        </div>
      </div>
    </header>
  );
};