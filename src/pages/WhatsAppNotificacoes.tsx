import { Bell, Plus, Clock, CheckCircle, XCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const templates = [
  { id: 1, name: "Chamada Perdida", trigger: "Chamada não atendida", active: true },
  { id: 2, name: "Novo Voicemail", trigger: "Voicemail recebido", active: true },
  { id: 3, name: "Lembrete de Retorno", trigger: "30min após chamada perdida", active: false },
];

const history = [
  { to: "+55 11 99999-0001", template: "Chamada Perdida", time: "14:32", status: "enviado" },
  { to: "+55 11 99999-0002", template: "Novo Voicemail", time: "14:15", status: "enviado" },
  { to: "+55 21 98888-1234", template: "Chamada Perdida", time: "13:55", status: "falhou" },
  { to: "+55 31 97777-5678", template: "Chamada Perdida", time: "12:40", status: "enviado" },
];

const WhatsAppNotificacoes = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Notificações WhatsApp</h1>
        <p className="text-muted-foreground text-sm">Configure alertas automáticos via WhatsApp</p>
      </div>
      <Button className="bg-primary text-primary-foreground">
        <Plus className="h-4 w-4 mr-2" /> Novo Template
      </Button>
    </div>

    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {templates.map((t) => (
        <Card key={t.id} className="bg-card border-border">
          <CardContent className="p-4">
            <div className="flex items-center gap-3 mb-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-info/10">
                <Bell className="h-4 w-4 text-info" />
              </div>
              <div>
                <p className="font-medium text-sm">{t.name}</p>
                <p className="text-xs text-muted-foreground">{t.trigger}</p>
              </div>
            </div>
            <Badge className={t.active ? "bg-success/10 text-success" : "bg-muted text-muted-foreground"}>
              {t.active ? "Ativo" : "Inativo"}
            </Badge>
          </CardContent>
        </Card>
      ))}
    </div>

    <Card className="bg-card border-border">
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium flex items-center gap-2">
          <Clock className="h-4 w-4 text-primary" /> Histórico de Envios
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {history.map((h, i) => (
            <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
              <div>
                <p className="text-sm font-mono">{h.to}</p>
                <p className="text-xs text-muted-foreground">{h.template}</p>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted-foreground">{h.time}</span>
                {h.status === "enviado" ? (
                  <CheckCircle className="h-4 w-4 text-success" />
                ) : (
                  <XCircle className="h-4 w-4 text-destructive" />
                )}
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  </div>
);

export default WhatsAppNotificacoes;
