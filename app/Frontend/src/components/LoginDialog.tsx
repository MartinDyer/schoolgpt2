import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Building2 } from "lucide-react";
import { signInWithMicrosoft, accountToUser } from "@/lib/auth/msal";

interface LoginDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onLogin: (user: { name: string; email: string; avatar: string }) => void;
}

export const LoginDialog = ({ open, onOpenChange, onLogin }: LoginDialogProps) => {
  const [isLoading, setIsLoading] = useState(false);

  const handleMicrosoftLogin = async () => {
  try {
    setIsLoading(true);
    const account = await signInWithMicrosoft();
    const user = accountToUser(account);
    if (user) onLogin(user);      // <- keeps your existing flow intact
    onOpenChange(false);
  } catch (e) {
    console.error(e);
  } finally {
    setIsLoading(false);
  }
};

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader className="text-center">
          <DialogTitle className="text-2xl font-semibold text-foreground">
            Sign in to School-Safe-AI
          </DialogTitle>
          <p className="text-sm text-muted-foreground mt-2">
            Please sign in with your school Microsoft account to access your chat history and personalized features.
          </p>
        </DialogHeader>
        
        <div className="space-y-4 pt-4">
          <Button 
            onClick={handleMicrosoftLogin}
            disabled={isLoading}
            className="w-full h-12 bg-[#0078d4] hover:bg-[#106ebe] text-white font-medium"
            size="lg"
          >
            <Building2 className="w-5 h-5 mr-3" />
            {isLoading ? "Signing in..." : "Sign in with Microsoft"}
          </Button>
          
          <div className="text-center">
            <p className="text-xs text-muted-foreground">
              By signing in, you agree to our Terms of Service and Privacy Policy.
              This service is designed specifically for educational use.
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};