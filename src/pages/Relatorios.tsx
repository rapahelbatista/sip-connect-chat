import { BarChart3, Download, Filter } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";

const weeklyData = [
  { dia: "Seg", entrada: 45, saida: 32, perdidas: 5 },
  { dia: "Ter", entrada: 52, saida: 41, perdidas: 8 },
  { dia: "Qua", entrada: 38, saida: 29, perdidas: 3 },
  { dia: "Qui", entrada: 61, saida: 48, perdidas: 7 },
  { dia: "Sex", entrada: 43, saida: 35, perdidas: 4 },
];

const pieData = [
  { name: "Atendidas", value: 82, color: "hsl(152, 69%, 42%)" },
  { name: "Perdidas", value: 12, color: "hsl(0, 72%, 51%)" },
  { name: "Em fila", value: 6, color: "hsl(38, 92%, 50%)" },
];

const Relatorios = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Relatórios</h1>
        <p className="text-muted-foreground text-sm">Análise de chamadas e atendimento</p>
      </div>
      <div className="flex gap-2">
        <Button variant="outline"><Filter className="h-4 w-4 mr-2" /> Filtros</Button>
        <Button variant="outline"><Download className="h-4 w-4 mr-2" /> Exportar</Button>
      </div>
    </div>

    <div className="flex gap-4 items-center max-w-lg">
      <Input type="date" className="flex-1" />
      <span className="text-muted-foreground text-sm">até</span>
      <Input type="date" className="flex-1" />
    </div>

    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <Card className="lg:col-span-2 bg-card border-border">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <BarChart3 className="h-4 w-4 text-primary" /> Chamadas por Dia
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={weeklyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(220, 15%, 16%)" />
                <XAxis dataKey="dia" stroke="hsl(215, 15%, 55%)" fontSize={12} />
                <YAxis stroke="hsl(215, 15%, 55%)" fontSize={12} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "hsl(222, 22%, 9%)",
                    border: "1px solid hsl(220, 15%, 16%)",
                    borderRadius: "8px",
                    color: "hsl(210, 20%, 90%)",
                  }}
                />
                <Bar dataKey="entrada" fill="hsl(217, 91%, 60%)" radius={[4, 4, 0, 0]} />
                <Bar dataKey="saida" fill="hsl(152, 69%, 42%)" radius={[4, 4, 0, 0]} />
                <Bar dataKey="perdidas" fill="hsl(0, 72%, 51%)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      <Card className="bg-card border-border">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium">Distribuição</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[220px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={pieData} dataKey="value" cx="50%" cy="50%" outerRadius={80} innerRadius={50} strokeWidth={0}>
                  {pieData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: "hsl(222, 22%, 9%)",
                    border: "1px solid hsl(220, 15%, 16%)",
                    borderRadius: "8px",
                    color: "hsl(210, 20%, 90%)",
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-2 mt-2">
            {pieData.map((d) => (
              <div key={d.name} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <div className="h-3 w-3 rounded-full" style={{ backgroundColor: d.color }} />
                  <span className="text-muted-foreground">{d.name}</span>
                </div>
                <span className="font-mono font-bold">{d.value}%</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
);

export default Relatorios;
