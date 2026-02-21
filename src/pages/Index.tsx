import { Phone, PhoneIncoming, PhoneMissed, PhoneOff, Users, Clock, TrendingUp } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from "recharts";

const stats = [
  { label: "Chamadas Ativas", value: "12", icon: Phone, color: "text-primary", bg: "bg-primary/10" },
  { label: "Em Fila", value: "5", icon: PhoneIncoming, color: "text-warning", bg: "bg-warning/10" },
  { label: "Finalizadas Hoje", value: "187", icon: PhoneOff, color: "text-success", bg: "bg-success/10" },
  { label: "Perdidas", value: "8", icon: PhoneMissed, color: "text-destructive", bg: "bg-destructive/10" },
];

const hourlyData = [
  { hora: "08h", chamadas: 12 }, { hora: "09h", chamadas: 28 },
  { hora: "10h", chamadas: 45 }, { hora: "11h", chamadas: 38 },
  { hora: "12h", chamadas: 22 }, { hora: "13h", chamadas: 15 },
  { hora: "14h", chamadas: 42 }, { hora: "15h", chamadas: 51 },
  { hora: "16h", chamadas: 36 }, { hora: "17h", chamadas: 24 },
];

const agents = [
  { name: "Ana Silva", ramal: "1001", status: "disponível", calls: 23 },
  { name: "Carlos Lima", ramal: "1002", status: "em chamada", calls: 19 },
  { name: "Maria Santos", ramal: "1003", status: "disponível", calls: 31 },
  { name: "João Ferreira", ramal: "1004", status: "ausente", calls: 12 },
  { name: "Beatriz Costa", ramal: "1005", status: "em chamada", calls: 27 },
];

const statusColor: Record<string, string> = {
  "disponível": "bg-success text-success-foreground",
  "em chamada": "bg-warning text-warning-foreground",
  "ausente": "bg-muted text-muted-foreground",
};

const Dashboard = () => {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground text-sm">Visão geral da central de comunicação</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => (
          <Card key={stat.label} className="bg-card border-border">
            <CardContent className="p-4 flex items-center gap-4">
              <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${stat.bg}`}>
                <stat.icon className={`h-6 w-6 ${stat.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold font-mono">{stat.value}</p>
                <p className="text-xs text-muted-foreground">{stat.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chart */}
        <Card className="lg:col-span-2 bg-card border-border">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-primary" />
              Volume de Chamadas por Hora
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={hourlyData}>
                  <defs>
                    <linearGradient id="colorChamadas" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="hsl(217, 91%, 60%)" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="hsl(217, 91%, 60%)" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(220, 15%, 16%)" />
                  <XAxis dataKey="hora" stroke="hsl(215, 15%, 55%)" fontSize={12} />
                  <YAxis stroke="hsl(215, 15%, 55%)" fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: "hsl(222, 22%, 9%)",
                      border: "1px solid hsl(220, 15%, 16%)",
                      borderRadius: "8px",
                      color: "hsl(210, 20%, 90%)",
                    }}
                  />
                  <Area
                    type="monotone"
                    dataKey="chamadas"
                    stroke="hsl(217, 91%, 60%)"
                    fillOpacity={1}
                    fill="url(#colorChamadas)"
                    strokeWidth={2}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Metrics */}
        <Card className="bg-card border-border">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="h-4 w-4 text-primary" />
              Métricas do Dia
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
              <span className="text-sm text-muted-foreground">Tempo Médio</span>
              <span className="font-mono font-bold text-primary">3:42</span>
            </div>
            <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
              <span className="text-sm text-muted-foreground">Taxa de Atendimento</span>
              <span className="font-mono font-bold text-success">95.7%</span>
            </div>
            <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
              <span className="text-sm text-muted-foreground">Tempo em Fila</span>
              <span className="font-mono font-bold text-warning">0:48</span>
            </div>
            <div className="flex justify-between items-center p-3 rounded-lg bg-muted/50">
              <span className="text-sm text-muted-foreground">SLA</span>
              <span className="font-mono font-bold text-info">89.2%</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Agents */}
      <Card className="bg-card border-border">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <Users className="h-4 w-4 text-primary" />
            Status dos Agentes
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {agents.map((agent) => (
              <div
                key={agent.ramal}
                className="flex items-center justify-between p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <div className="h-8 w-8 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold text-primary">
                    {agent.name.split(" ").map(n => n[0]).join("")}
                  </div>
                  <div>
                    <p className="text-sm font-medium">{agent.name}</p>
                    <p className="text-xs text-muted-foreground font-mono">Ramal {agent.ramal}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-xs text-muted-foreground font-mono">{agent.calls} chamadas</span>
                  <Badge className={`text-xs ${statusColor[agent.status]}`}>
                    {agent.status}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Dashboard;
