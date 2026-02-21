import { Bot, Plus, MessageSquare, ArrowRight, Power } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const flows = [
  {
    id: 1, name: "Menu Principal", active: true,
    trigger: "Qualquer mensagem inicial",
    steps: ["Saudação", "Menu de opções", "Encaminhamento"],
  },
  {
    id: 2, name: "FAQ Automático", active: true,
    trigger: "Palavras-chave: horário, preço, endereço",
    steps: ["Detectar intenção", "Resposta automática"],
  },
  {
    id: 3, name: "Agendamento", active: false,
    trigger: "Palavra-chave: agendar",
    steps: ["Coletar data", "Confirmar horário", "Registrar"],
  },
];

const WhatsAppChatbot = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Chatbot / URA WhatsApp</h1>
        <p className="text-muted-foreground text-sm">Configure fluxos de atendimento automático</p>
      </div>
      <Button className="bg-primary text-primary-foreground">
        <Plus className="h-4 w-4 mr-2" /> Novo Fluxo
      </Button>
    </div>

    <div className="space-y-4">
      {flows.map((flow) => (
        <Card key={flow.id} className="bg-card border-border hover:border-primary/30 transition-colors">
          <CardContent className="p-6">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-success/10">
                  <Bot className="h-5 w-5 text-success" />
                </div>
                <div>
                  <h3 className="font-semibold">{flow.name}</h3>
                  <div className="flex items-center gap-2 mt-1">
                    <MessageSquare className="h-3 w-3 text-muted-foreground" />
                    <span className="text-xs text-muted-foreground">{flow.trigger}</span>
                  </div>
                </div>
              </div>
              <Badge className={flow.active ? "bg-success/10 text-success border-success/30" : "bg-muted text-muted-foreground"}>
                <Power className="h-3 w-3 mr-1" />
                {flow.active ? "Ativo" : "Inativo"}
              </Badge>
            </div>

            <div className="flex items-center gap-2 flex-wrap mb-4">
              {flow.steps.map((step, i) => (
                <span key={i} className="flex items-center gap-1">
                  <Badge variant="outline" className="text-xs">{step}</Badge>
                  {i < flow.steps.length - 1 && <ArrowRight className="h-3 w-3 text-muted-foreground" />}
                </span>
              ))}
            </div>

            <Button variant="outline" size="sm">Editar Fluxo</Button>
          </CardContent>
        </Card>
      ))}
    </div>
  </div>
);

export default WhatsAppChatbot;
