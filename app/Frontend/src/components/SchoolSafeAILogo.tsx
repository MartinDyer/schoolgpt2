import { cn } from "@/lib/utils";

interface SchoolSafeAILogoProps {
  className?: string;
  size?: "sm" | "md" | "lg";
}

export const SchoolSafeAILogo = ({ className, size = "md" }: SchoolSafeAILogoProps) => {
  const sizeClasses = {
    sm: "w-8 h-8",
    md: "w-12 h-12", 
    lg: "w-20 h-20"
  };

  return (
    <div className={cn("relative", sizeClasses[size], className)}>
      <div className="absolute inset-0 bg-logo-primary rounded-full flex items-center justify-center">
        <div className="w-3/5 h-3/5 bg-logo-secondary rounded-full flex items-center justify-center">
          <div className="w-2/5 h-2/5 bg-white rounded-full"></div>
        </div>
      </div>
    </div>
  );
};