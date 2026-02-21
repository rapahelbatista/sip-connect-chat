import { GitBranch, Plus, Clock, Volume2, ArrowRight } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const uraFlows = [
  {
    id: 1,
    name: "Atendimento Principal",
    active: true,
    options: ["1 - Vendas", "2 - Suporte", "3 - Financeiro", "0 - Atendente"],
    schedule: "Seg-Sex 08:00-18:00",
  },
  {
    id: 2,
    name: "Fora do Horário",
    active: true,
    options: ["1 - Deixar recado", "2 - Urgência"],
    schedule: "Seg-Sex 18:00-08:00, Sáb-Dom",
  },
  {
    id: 3,
    name: "Feriados",
    active: false,
    options: ["1 - Deixar recado"],
    schedule: "Conforme calendário",
  },
];

const URA = () => {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">URA</h1>
          <p className="text-muted-foreground text-sm">Configure os fluxos de atendimento automático</p>
        </div>
        <Button className="bg-primary text-primary-foreground">
          <Plus className="h-4 w-4 mr-2" /> Novo Fluxo
        </Button>
      </div>

      <div className="space-y-4">
        {uraFlows.map((flow) => (
          <Card key={flow.id} className="bg-card border-border hover:border-primary/30 transition-colors">
            <CardContent className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                    <GitBranch className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <h3 className="font-semibold">{flow.name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <Clock className="h-3 w-3 text-muted-foreground" />
                      <span className="text-xs text-muted-foreground">{flow.schedule}</span>
                    </div>
                  </div>
                </div>
                <Badge className={flow.active ? "bg-success/10 text-success border-success/30" : "bg-muted text-muted-foreground"}>
                  {flow.active ? "Ativo" : "Inativo"}
                </Badge>
              </div>

              <div className="flex flex-wrap gap-2 mb-4">
                <div className="flex items-center gap-1 text-xs text-muted-foreground">
                  <Volume2 className="h-3 w-3" /> Saudação
                  <ArrowRight className="h-3 w-3 mx-1" />
                </div>
                {flow.options.map((opt, i) => (
                  <Badge key={i} variant="outline" className="text-xs font-mono">
                    {opt}
                  </Badge>
                ))}
              </div>

              <Button variant="outline" size="sm">
                Editar Fluxo
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
};

export default URA;
