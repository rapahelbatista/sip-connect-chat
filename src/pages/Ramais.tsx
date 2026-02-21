import { Plus, Search, MoreVertical, Wifi, WifiOff } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";

const ramais = [
  { ramal: "1001", nome: "Ana Silva", status: "online", encaminhamento: "Nenhum", voicemail: true },
  { ramal: "1002", nome: "Carlos Lima", status: "online", encaminhamento: "(11) 99999-0000", voicemail: true },
  { ramal: "1003", nome: "Maria Santos", status: "offline", encaminhamento: "Nenhum", voicemail: false },
  { ramal: "1004", nome: "João Ferreira", status: "online", encaminhamento: "Nenhum", voicemail: true },
  { ramal: "1005", nome: "Beatriz Costa", status: "offline", encaminhamento: "Ramal 1001", voicemail: true },
  { ramal: "1006", nome: "Pedro Oliveira", status: "online", encaminhamento: "Nenhum", voicemail: false },
];

const Ramais = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Ramais</h1>
          <p className="text-muted-foreground text-sm">Gerencie os ramais da central</p>
        </div>
        <Button className="bg-primary text-primary-foreground">
          <Plus className="h-4 w-4 mr-2" /> Novo Ramal
        </Button>
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Buscar ramal..." className="pl-9" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {ramais.map((r) => (
          <Card key={r.ramal} className="bg-card border-border hover:border-primary/30 transition-colors">
            <CardContent className="p-4">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center text-sm font-bold text-primary font-mono">
                    {r.ramal}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{r.nome}</p>
                    <p className="text-xs text-muted-foreground font-mono">Ramal {r.ramal}</p>
                  </div>
                </div>
                <Button variant="ghost" size="icon" className="h-8 w-8">
                  <MoreVertical className="h-4 w-4" />
                </Button>
              </div>
              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Status</span>
                  <Badge variant="outline" className={r.status === "online" ? "border-success text-success" : "border-muted text-muted-foreground"}>
                    {r.status === "online" ? <Wifi className="h-3 w-3 mr-1" /> : <WifiOff className="h-3 w-3 mr-1" />}
                    {r.status}
                  </Badge>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Encaminhamento</span>
                  <span className="font-mono">{r.encaminhamento}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Voicemail</span>
                  <span>{r.voicemail ? "Ativado" : "Desativado"}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default Ramais;
