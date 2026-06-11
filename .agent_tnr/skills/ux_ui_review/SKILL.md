---
name: UX & UI Review - Tô Na Rota
description: Realiza uma análise de interface gráfica e usabilidade de códigos Flutter, garantindo o padrão estético premium do projeto.
---

# Skill: Revisão de UX & UI (UX & UI Review)

Você ativou a skill de Revisão de Design e Usabilidade para o projeto **Tô Na Rota**. Seu objetivo é validar componentes e telas implementadas em Flutter. O padrão de qualidade visual deste projeto é de nível global ("Wow factor").

## Como Executar a Revisão

### Passo 1: Análise de Layout Estrutural
- A tela utiliza `SafeArea` para evitar sobreposição nos recortes do aparelho (notch/status bar)?
- Os paddings e margins seguem um grid padronizado (ex: múltiplos de 8)?
- A interface é responsiva? No Web (Admin/SaaS), ela utiliza `LayoutBuilder` ou `MediaQuery` para adaptar as colunas? No Mobile, ela se adapta bem a telas menores?

### Passo 2: Estética Premium e Micro-interações
- Os cartões/cards usam sombras sutis (`BoxShadow` com blur raios altos e opacidades baixas) em vez de bordas duras?
- A tipografia principal do projeto (Inter, Roboto ou Outfit) está sendo utilizada com o `TextTheme` correto? Há hierarquia visual clara (H1, H2, Body)?
- Existem animações fluidas? Os botões e cards de estabelecimentos têm efeitos de hover ou tap (`InkWell`, `AnimatedContainer`)?

### Passo 3: Feedback de Conversão
- Os Botões de Ação (CTAs principais) são destacados, visíveis e ergonomicamente fáceis de tocar (mínimo de 48x48 dp)?
- No card de estabelecimentos Premium, as fotos do carrossel têm tratamento para erro de carregamento e *skeleton loaders* (placeholders animados) estão configurados?

### Passo 4: Retorno da Análise
Se identificar que o layout está rudimentar, sugira imediatamente as refatorações necessárias fornecendo exemplos práticos em código, especialmente refatorando `Container` e `BoxDecoration` para um estilo mais moderno (ex: uso de cores de superfície, elevações graduais e bordas arredondadas modernas - radius 12 ou 16).
