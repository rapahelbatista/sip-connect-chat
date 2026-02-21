

# Central de Comunicação - Painel Web

## Visão Geral
Painel web moderno para gerenciamento de telefonia (Asterisk) e WhatsApp, com softphone integrado e configuração de URA.

> **Nota:** Este painel é a interface web. A configuração do Asterisk no VPS e da API de WhatsApp (ex: Evolution API) deve ser feita separadamente. O painel se conectará a essas APIs.

---

## Páginas e Funcionalidades

### 1. Dashboard Principal
- Resumo de chamadas ativas, em fila e finalizadas
- Métricas em tempo real (tempo médio de atendimento, chamadas perdidas)
- Status dos agentes/ramais
- Gráficos de volume de chamadas por hora/dia

### 2. Softphone WebRTC
- Interface de discagem integrada no painel (teclado numérico)
- Receber/fazer chamadas pelo navegador
- Controles: mudo, espera, transferência
- Histórico de chamadas recentes
- Indicador de status (disponível, ocupado, ausente)

### 3. Gerenciamento de Ramais
- Lista de ramais cadastrados
- Criar/editar/excluir ramais
- Status online/offline de cada ramal
- Configurações por ramal (encaminhamento, voicemail)

### 4. URA (Unidade de Resposta Audível)
- Editor visual de fluxo de atendimento (drag & drop)
- Configurar menus de opções (ex: "Pressione 1 para vendas...")
- Definir horários de funcionamento
- Configurar mensagens de espera e saudação
- Encaminhamento para filas ou ramais específicos

### 5. Chat WhatsApp
- Interface de chat para visualizar e responder mensagens
- Lista de conversas ativas
- Envio de mensagens de texto, imagens e documentos
- Templates de mensagens rápidas
- Indicador de mensagens não lidas

### 6. Chatbot/URA WhatsApp
- Configurar fluxo de atendimento automático via WhatsApp
- Menu de opções interativo
- Respostas automáticas por palavra-chave
- Encaminhamento para atendente humano

### 7. Notificações WhatsApp
- Configurar alertas automáticos (chamada perdida, novo voicemail)
- Templates de notificação
- Histórico de notificações enviadas

### 8. Relatórios
- Relatório de chamadas (entrada/saída/perdidas)
- Relatório de atendimento WhatsApp
- Exportação em formato básico
- Filtros por data, ramal e agente

---

## Design
- Layout moderno e escuro (dark mode) com sidebar de navegação
- Interface responsiva
- Cards com métricas em destaque
- Cores: tons de azul e cinza escuro (estilo profissional de telecom)

---

## Backend Necessário
- Lovable Cloud com Supabase para autenticação de usuários e armazenamento de configurações
- Edge Functions para intermediar chamadas às APIs do Asterisk (AMI/ARI) e WhatsApp

