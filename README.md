# Barber Hub 💈

App mobile de barbearia construído com Flutter, com backend em Supabase (Postgres + Auth + Row Level Security). Cobre três perfis de uso: **cliente** (agenda cortes, assina planos, avalia atendimentos), **barbearia** (gerencia agenda, equipe, produtos, planos de assinatura) e **admin** (visão geral do catálogo).

---

## 🚀 Como rodar

```bash
# 1. Instale as dependências
flutter pub get

# 2. Execute o app
flutter run

# 3. Gere um APK de release
flutter build apk --release
```

> Requer Flutter 3.10+ e Dart 3.0+

### Backend (Supabase)

As credenciais do projeto Supabase estão em `lib/core/config/supabase_config.dart`. Os arquivos de migration (schema + RLS) ficam em `supabase/migrations/`, em ordem cronológica — aplique todos com:

```bash
supabase db push
```

(ou colando o SQL de cada migration pendente no editor SQL do painel do Supabase). O app funciona com dados mock quando o Supabase não está configurado, mas todas as funcionalidades reais (agendamento, assinaturas, avaliações) dependem do backend estar com as migrations aplicadas e o cache de schema do PostgREST atualizado.

---

## 👥 Perfis de usuário

| Perfil       | Acesso                                                                 |
|--------------|-------------------------------------------------------------------------|
| `client`     | Navega barbearias, agenda serviços, assina planos, avalia atendimentos |
| `barberShop` | Painel de gestão da própria barbearia (agenda, equipe, planos, etc.)   |
| `barber`     | Perfil legado de barbeiro individual (telas mantidas, não é o fluxo principal) |
| `admin`      | Visão geral do catálogo (barbearias, barbeiros, serviços)              |

O cadastro/login é feito via Supabase Auth; o roteamento inicial (`splash_screen`) decide o shell correto (`MainShell`, `BarberShopShell`, `BarberShell` ou `AdminShell`) de acordo com o `role` do perfil autenticado.

---

## ✨ Funcionalidades

### Cliente
- Listagem e busca de barbearias, com detalhes (serviços, produtos, equipe, avaliações, planos)
- Agendamento de serviços por barbeiro/data/horário — respeita o horário de funcionamento (por dia da semana) e datas bloqueadas pela barbearia
- Carrinho e compra de produtos
- **Assinaturas (membership)**: ver planos ativos de uma barbearia, assinar, fazer upgrade de plano, pausar/reativar/cancelar (cancelamento exclui a assinatura, não deixa registro "fantasma")
- Resgate de corte incluso na assinatura no momento do agendamento
- Avaliação de atendimentos concluídos (nota separada para barbearia e para o barbeiro + comentário)
- Assistente de IA ("Barber IA") com contexto real do app (Groq ou Ollama local), restrito a temas de barbearia
- Histórico de agendamentos, perfil e edição de dados

### Barbearia (`barberShop`)
- Dashboard com indicadores gerais
- Gestão de serviços, barbeiros e produtos (CRUD completo)
- Agenda: visualizar agendamentos do dia, marcar como concluído/cancelado (necessário para liberar a avaliação do cliente)
- Bloqueio de datas (feriados, manutenção, todos os sábados/domingos) — reflete direto na disponibilidade vista pelo cliente
- Configurações: horário de funcionamento por dia da semana, dados da barbearia
- Gestão de planos de assinatura: criar, editar, ativar/desativar e excluir planos (máximo 1 plano por tier — Basic/Premium/VIP), ver assinantes e registrar uso de corte
- Visão de avaliações recebidas (geral e por barbeiro)

### Admin (legado)
- Visão geral de barbearias, barbeiros e serviços cadastrados

---

## 🏗️ Arquitetura

O projeto está em transição de uma arquitetura legada (Provider) para uma estrutura em camadas (Riverpod). As duas convivem hoje:

- **`lib/features/*`** — código novo, organizado em `data/domain/presentation` por feature (`auth`, `barber_shop`, `membership`), state management com `flutter_riverpod`, persistência via Supabase.
- **`lib/screens`, `lib/models`, `lib/data`, `lib/widgets`** — código legado (telas do cliente, admin e barbeiro individual), state management com `provider`/`ChangeNotifier`, ainda em uso ativo (ex.: `AppDataProvider` centraliza agendamentos, catálogo, avaliações e datas bloqueadas para o lado cliente).

Pontos de integração entre os dois mundos (ex.: tela de detalhe da barbearia, no lado cliente, consumindo o provider de assinaturas do Riverpod) usam `ConsumerStatefulWidget`/`Consumer` dentro de widgets que também escutam `provider.Provider`.

---

## 🔧 Stack

| Camada              | Tecnologia                                  |
|---------------------|----------------------------------------------|
| UI                  | Flutter (Material, tema dark customizado)    |
| Estado (legado)      | `provider` (`ChangeNotifier`)                |
| Estado (novo)        | `flutter_riverpod`                           |
| Backend             | Supabase (Postgres, Auth, Row Level Security, PostgREST) |
| Persistência local  | `shared_preferences` (cache/fallback offline)|
| Assistente de IA    | Groq API (cloud) ou Ollama (local, via `http`) |
| Ícones              | `flutter_lucide` + Material Icons            |
| Tipografia          | Google Fonts — Cormorant Garamond (display) + Jost (corpo) |

---

## 🗂️ Estrutura do projeto

```
lib/
├── main.dart                      # Entry point + tabela de rotas
│
├── core/
│   ├── config/supabase_config.dart
│   ├── constants/                 # UserRole, constantes gerais
│   ├── errors/failures.dart       # Hierarquia de Failure do domínio
│   ├── routes/app_routes.dart
│   ├── services/                  # SupabaseService, GroqService, OllamaService,
│   │                               # BarberhubContextService (contexto para a IA)
│   ├── theme/app_theme.dart
│   └── utils/
│
├── features/                      # Arquitetura nova (Riverpod)
│   ├── auth/                      # Login, registro, recuperação de senha
│   ├── barber_shop/                # Painel da barbearia (agenda, equipe, settings...)
│   ├── client/data/models/         # Modelos compartilhados pelo lado novo
│   └── membership/                 # Planos de assinatura (cliente + barbearia)
│
├── screens/                        # Telas legadas (Provider)
│   ├── client/                     # Home, busca, detalhe de barbearia, booking, carrinho...
│   ├── admin/
│   └── barber/
│
├── models/                         # Modelos + AppDataProvider (legado, lado cliente)
├── data/                           # Datasources Supabase usados pelo lado legado
├── widgets/ , shared/widgets/       # Componentes reutilizáveis (duplicados entre os 2 mundos)
└── mock/ , shared/mock/             # Dados mock usados quando o Supabase não está configurado

supabase/migrations/                # Schema + RLS, em ordem cronológica
```

---

## 🎨 Design

- **Tema**: dark, com acentos dourados
- **Tipografia**: Cormorant Garamond (display) + Jost (corpo)
- **Paleta**: preto profundo + dourado (`AppTheme.gold`)
- **Animações**: fade/slide nas transições de tela, loading states em botões e ações assíncronas
