import { useState } from "react";
import { Phone, PhoneOff, Mic, MicOff, Pause, ArrowRightLeft, Delete } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

const dialPad = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"];

const recentCalls = [
  { number: "(11) 98765-4321", type: "saída", duration: "3:42", time: "14:30" },
  { number: "(11) 91234-5678", type: "entrada", duration: "1:15", time: "14:12" },
  { number: "(21) 99876-5432", type: "perdida", duration: "-", time: "13:55" },
  { number: "(11) 95555-1234", type: "saída", duration: "5:08", time: "13:20" },
  { number: "(31) 98888-7777", type: "entrada", duration: "2:33", time: "12:45" },
];

const typeColor: Record<string, string> = {
  saída: "text-primary",
  entrada: "text-success",
  perdida: "text-destructive",
};

const Softphone = () => {
  const [number, setNumber] = useState("");
  const [inCall, setInCall] = useState(false);
  const [muted, setMuted] = useState(false);
  const [onHold, setOnHold] = useState(false);

  const handleDial = (digit: string) => setNumber((prev) => prev + digit);
  const handleDelete = () => setNumber((prev) => prev.slice(0, -1));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Softphone</h1>
        <p className="text-muted-foreground text-sm">Faça e receba chamadas pelo navegador</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 max-w-4xl">
        {/* Dialpad */}
        <Card className="bg-card border-border">
          <CardHeader className="pb-2 text-center">
            <Badge className={inCall ? "bg-success text-success-foreground" : "bg-muted text-muted-foreground"} >
              {inCall ? "Em chamada" : "Disponível"}
            </Badge>
          </CardHeader>
          <CardContent className="flex flex-col items-center gap-4">
            {/* Display */}
            <div className="w-full bg-muted/50 rounded-lg p-4 text-center min-h-[60px] flex items-center justify-center">
              <span className="text-2xl font-mono font-bold tracking-widest">
                {number || <span className="text-muted-foreground text-lg">Digite o número</span>}
              </span>
            </div>

            {/* Pad */}
            <div className="grid grid-cols-3 gap-2 w-full max-w-[240px]">
              {dialPad.map((digit) => (
                <Button
                  key={digit}
                  variant="outline"
                  className="h-14 text-xl font-mono font-bold hover:bg-primary/10 hover:text-primary hover:border-primary/30"
                  onClick={() => handleDial(digit)}
                >
                  {digit}
                </Button>
              ))}
            </div>

            {/* Controls */}
            <div className="flex gap-2 w-full max-w-[240px]">
              {!inCall ? (
                <>
                  <Button
                    className="flex-1 h-12 bg-success hover:bg-success/90 text-success-foreground"
                    onClick={() => setInCall(true)}
                    disabled={!number}
                  >
                    <Phone className="h-5 w-5 mr-2" /> Ligar
                  </Button>
                  <Button variant="outline" className="h-12" onClick={handleDelete} disabled={!number}>
                    <Delete className="h-5 w-5" />
                  </Button>
                </>
              ) : (
                <>
                  <Button
                    variant="outline"
                    className={`h-12 ${muted ? "bg-destructive/20 text-destructive border-destructive/30" : ""}`}
                    onClick={() => setMuted(!muted)}
                  >
                    {muted ? <MicOff className="h-5 w-5" /> : <Mic className="h-5 w-5" />}
                  </Button>
                  <Button
                    variant="outline"
                    className={`h-12 ${onHold ? "bg-warning/20 text-warning border-warning/30" : ""}`}
                    onClick={() => setOnHold(!onHold)}
                  >
                    <Pause className="h-5 w-5" />
                  </Button>
                  <Button variant="outline" className="h-12">
                    <ArrowRightLeft className="h-5 w-5" />
                  </Button>
                  <Button
                    className="h-12 bg-destructive hover:bg-destructive/90 text-destructive-foreground"
                    onClick={() => { setInCall(false); setMuted(false); setOnHold(false); }}
                  >
                    <PhoneOff className="h-5 w-5" />
                  </Button>
                </>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Recent Calls */}
        <Card className="bg-card border-border">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Chamadas Recentes</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {recentCalls.map((call, i) => (
              <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors">
                <div>
                  <p className="text-sm font-mono font-medium">{call.number}</p>
                  <p className={`text-xs ${typeColor[call.type]}`}>{call.type}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-muted-foreground font-mono">{call.duration}</p>
                  <p className="text-xs text-muted-foreground">{call.time}</p>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default Softphone;
