import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AppLayout } from "@/components/AppLayout";
import Index from "./pages/Index";
import Softphone from "./pages/Softphone";
import Ramais from "./pages/Ramais";
import URA from "./pages/URA";
import WhatsAppChat from "./pages/WhatsAppChat";
import WhatsAppChatbot from "./pages/WhatsAppChatbot";
import WhatsAppNotificacoes from "./pages/WhatsAppNotificacoes";
import Relatorios from "./pages/Relatorios";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AppLayout>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/softphone" element={<Softphone />} />
            <Route path="/ramais" element={<Ramais />} />
            <Route path="/ura" element={<URA />} />
            <Route path="/whatsapp/chat" element={<WhatsAppChat />} />
            <Route path="/whatsapp/chatbot" element={<WhatsAppChatbot />} />
            <Route path="/whatsapp/notificacoes" element={<WhatsAppNotificacoes />} />
            <Route path="/relatorios" element={<Relatorios />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </AppLayout>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
