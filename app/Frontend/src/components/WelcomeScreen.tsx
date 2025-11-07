import { SchoolSafeAILogo } from "./SchoolSafeAILogo";

export const WelcomeScreen = () => {
  return (
    <div className="flex flex-col items-center justify-center flex-1 px-6 py-12">
      <div className="text-center max-w-2xl">
        <div className="mb-8">
          <SchoolSafeAILogo size="lg" className="mx-auto mb-6" />
        </div>
        
        <h1 className="text-4xl font-bold text-foreground mb-4">
          Start chatting
        </h1>
        
        <p className="text-lg text-muted-foreground leading-relaxed">
          This chatbot is configured to provide safe, educational responses for students. 
          Ask questions about your schoolwork or explore new topics in a secure environment.
        </p>
        
        <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-4 max-w-lg mx-auto">
          <div className="bg-card border border-border rounded-lg p-4 text-left">
            <h3 className="font-semibold text-foreground mb-2">Safe Learning</h3>
            <p className="text-sm text-muted-foreground">
              All responses are filtered for age-appropriate content
            </p>
          </div>
          
          <div className="bg-card border border-border rounded-lg p-4 text-left">
            <h3 className="font-semibold text-foreground mb-2">Educational Focus</h3>
            <p className="text-sm text-muted-foreground">
              Designed to help with homework and learning
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};