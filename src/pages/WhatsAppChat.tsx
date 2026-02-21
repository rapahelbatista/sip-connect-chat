import { useState } from "react";
import { Send, Paperclip, Search, Image, FileText, MoreVertical } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";

const conversations = [
  { id: 1, name: "João Cliente", phone: "+55 11 99999-0001", lastMsg: "Preciso de suporte", time: "14:30", unread: 3 },
  { id: 2, name: "Maria Fornecedora", phone: "+55 11 99999-0002", lastMsg: "Enviei o orçamento", time: "14:15", unread: 0 },
  { id: 3, name: "Pedro Parceiro", phone: "+55 21 98888-1234", lastMsg: "Quando podemos agendar?", time: "13:50", unread: 1 },
  { id: 4, name: "Ana Prospects", phone: "+55 31 97777-5678", lastMsg: "Obrigada pela informação", time: "12:20", unread: 0 },
  { id: 5, name: "Carlos Suporte", phone: "+55 11 96666-9999", lastMsg: "Problema resolvido!", time: "11:45", unread: 0 },
];

const messages = [
  { id: 1, from: "client", text: "Olá, boa tarde!", time: "14:20" },
  { id: 2, from: "client", text: "Preciso de suporte com minha conta", time: "14:22" },
  { id: 3, from: "agent", text: "Olá João! Claro, como posso ajudá-lo?", time: "14:25" },
  { id: 4, from: "client", text: "Não consigo acessar o painel de controle", time: "14:28" },
  { id: 5, from: "agent", text: "Vou verificar sua conta agora mesmo. Um momento, por favor.", time: "14:29" },
  { id: 6, from: "client", text: "Preciso de suporte", time: "14:30" },
];

const WhatsAppChat = () => {
  const [selected, setSelected] = useState(1);
  const [msg, setMsg] = useState("");

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">WhatsApp Chat</h1>
        <p className="text-muted-foreground text-sm">Gerencie conversas via WhatsApp</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[340px_1fr] gap-4 h-[calc(100vh-220px)]">
        {/* Contact List */}
        <Card className="bg-card border-border flex flex-col">
          <div className="p-3 border-b border-border">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input placeholder="Buscar conversa..." className="pl-9 h-9" />
            </div>
          </div>
          <ScrollArea className="flex-1">
            {conversations.map((c) => (
              <button
                key={c.id}
                onClick={() => setSelected(c.id)}
                className={`w-full text-left p-3 border-b border-border hover:bg-muted/50 transition-colors ${
                  selected === c.id ? "bg-muted/50 border-l-2 border-l-primary" : ""
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-success/20 flex items-center justify-center text-sm font-bold text-success">
                      {c.name.split(" ").map(n => n[0]).join("")}
                    </div>
                    <div className="min-w-0">
                      <p className="font-medium text-sm truncate">{c.name}</p>
                      <p className="text-xs text-muted-foreground truncate">{c.lastMsg}</p>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 ml-2">
                    <p className="text-xs text-muted-foreground">{c.time}</p>
                    {c.unread > 0 && (
                      <Badge className="bg-success text-success-foreground h-5 w-5 p-0 flex items-center justify-center text-xs mt-1 ml-auto">
                        {c.unread}
                      </Badge>
                    )}
                  </div>
                </div>
              </button>
            ))}
          </ScrollArea>
        </Card>

        {/* Chat Window */}
        <Card className="bg-card border-border flex flex-col">
          <div className="flex items-center justify-between p-3 border-b border-border">
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-full bg-success/20 flex items-center justify-center text-sm font-bold text-success">
                JC
              </div>
              <div>
                <p className="font-medium text-sm">João Cliente</p>
                <p className="text-xs text-success">Online</p>
              </div>
            </div>
            <Button variant="ghost" size="icon"><MoreVertical className="h-4 w-4" /></Button>
          </div>

          <ScrollArea className="flex-1 p-4">
            <div className="space-y-3">
              {messages.map((m) => (
                <div key={m.id} className={`flex ${m.from === "agent" ? "justify-end" : "justify-start"}`}>
                  <div
                    className={`max-w-[70%] px-3 py-2 rounded-lg text-sm ${
                      m.from === "agent"
                        ? "bg-primary text-primary-foreground rounded-br-sm"
                        : "bg-muted rounded-bl-sm"
                    }`}
                  >
                    <p>{m.text}</p>
                    <p className={`text-xs mt-1 ${m.from === "agent" ? "text-primary-foreground/70" : "text-muted-foreground"}`}>
                      {m.time}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </ScrollArea>

          <div className="p-3 border-t border-border flex items-center gap-2">
            <Button variant="ghost" size="icon"><Paperclip className="h-4 w-4" /></Button>
            <Button variant="ghost" size="icon"><Image className="h-4 w-4" /></Button>
            <Input
              placeholder="Digite uma mensagem..."
              className="flex-1"
              value={msg}
              onChange={(e) => setMsg(e.target.value)}
            />
            <Button className="bg-success hover:bg-success/90 text-success-foreground" disabled={!msg}>
              <Send className="h-4 w-4" />
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
};

export default WhatsAppChat;
