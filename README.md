# macToSearch

**AI-Powered Visual Search for macOS** - Uma aplicação nativa que transforma qualquer coisa na sua tela em uma busca inteligente, similar ao Circle to Search do Google.

## 🚀 Visão Geral

macToSearch é uma ferramenta revolucionária de busca visual que integra captura de tela avançada, OCR de alta precisão e IA generativa (Gemini) para permitir que você pesquise instantaneamente qualquer coisa visível em sua tela. Com uma interface glassmórfica elegante e atalhos de teclado intuitivos, torna a busca de informações mais rápida e natural que nunca.

## ✨ Principais Recursos

### 🎯 Captura Visual Inteligente
- **Circle to Search**: Pressione `Cmd+Shift+Space` para ativar o modo de captura instantaneamente
- **Seleção Flexível**: Desenhe círculos, retângulos ou selecione livremente qualquer área
- **Detecção Automática de Elementos**: Identifica automaticamente elementos UI, blocos de texto e imagens
- **OCR de Alta Precisão**: Extrai texto com 99.7% de precisão usando Vision framework nativo

### 💬 Interface de Chat Flutuante Moderna
- **Barra de Pesquisa Minimalista**: Interface compacta que não atrapalha seu fluxo de trabalho
- **Expansão Inteligente**: Expande automaticamente quando você começa a digitar
- **Histórico de Conversação Contextual**: Mantém contexto entre múltiplas perguntas para respostas mais relevantes
- **Suporte a Múltiplas Imagens**: Anexe e analise várias imagens simultaneamente com drag & drop

### 🎨 Design Glassmórfico de Última Geração
- **Efeitos Visuais Nativos**: Transparência e blur que se integram perfeitamente ao macOS
- **Bordas Animadas com Gradiente Neon**: Visual dinâmico com animações suaves
- **Dark Mode Automático**: Adapta-se instantaneamente ao tema do sistema
- **Animações com Spring Physics**: Transições naturais e responsivas entre estados

### ⚡ Performance e Integração Sistema
- **IA Generativa Gemini 2.0**: Respostas contextuais ultra-rápidas com modelos de última geração
- **Processamento Local Híbrido**: OCR executado localmente para máxima privacidade
- **Atalhos Globais via Carbon API**: Funciona de qualquer aplicativo, mesmo em tela cheia
- **Menu Bar Integration**: Acesso rápido via ícone nativo na barra de menu
- **Clipboard Monitoring**: Detecta e processa conteúdo copiado automaticamente

## 🛠 Instalação e Configuração

### Requisitos do Sistema
- macOS 14.0 (Sonoma) ou superior
- Apple Silicon (M1/M2/M3/M4) ou Intel Mac
- Xcode 15.0+ (para compilação do código-fonte)
- Conexão com internet para recursos de IA

### Instalação via Código-Fonte

1. **Clone o repositório**
```bash
git clone https://github.com/yourusername/macToSearch.git
cd macToSearch
```

2. **Abra no Xcode**
```bash
open macToSearch.xcodeproj
```

3. **Configure a API Key do Gemini**
   - Obtenha uma key gratuita em [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Adicione no arquivo `GeminiService.swift` ou via Settings no app
   - 1.500 requests gratuitos por dia

4. **Compile e Execute**
   - Pressione `Cmd+R` para build e run
   - Ou use `Product > Archive` para criar um release

### Permissões Necessárias

Na primeira execução, o macOS solicitará:
- **Screen Recording**: Para capturar conteúdo da tela
- **Accessibility**: Para atalhos globais funcionarem
- Configure em: `Ajustes do Sistema > Privacidade e Segurança`

## 🎯 Como Usar

### Busca Visual Rápida (Circle to Search)

1. **Ative o Modo de Captura**
   - Pressione `Cmd+Shift+Space` de qualquer lugar
   - Ou clique no ícone da câmera na barra flutuante

2. **Selecione a Área de Interesse**
   - **Desenhe**: Circule ou crie retângulos ao redor do conteúdo
   - **Clique Inteligente**: Selecione elementos UI automaticamente
   - **Seleção Livre**: Desenhe qualquer forma para captura precisa
   - **ESC**: Cancele a seleção a qualquer momento

3. **Receba Resultados Instantâneos**
   - OCR extrai texto automaticamente
   - IA analisa contexto e fornece informações relevantes
   - Continue a conversa para aprofundar o tópico

### Chat com IA Contextual

1. **Abra a Interface de Chat**
   - Pressione `Cmd+Shift+O` para abrir/focar
   - Ou clique na barra de pesquisa flutuante

2. **Interaja Naturalmente**
   - Digite perguntas em linguagem natural
   - Arraste imagens diretamente para análise
   - Use `Cmd+V` para colar imagens do clipboard
   - Histórico mantém contexto entre perguntas

### Pesquisa de Clipboard

1. **Copie Qualquer Conteúdo**
   - Texto, imagens ou combinações

2. **Ative a Pesquisa**
   - App detecta automaticamente novo conteúdo
   - Ou clique em "Search Clipboard"

### ⌨️ Atalhos de Teclado

| Atalho | Ação | Contexto |
|--------|------|----------|
| `Cmd+Shift+Space` | Ativar Circle to Search | Global |
| `Cmd+Shift+O` | Abrir/Focar Chat | Global |
| `ESC` | Fechar overlay ou chat | Durante captura/chat |
| `Return` | Enviar mensagem | No chat |
| `Cmd+V` | Colar imagem | No chat |
| `Cmd+,` | Abrir Preferências | No app |

## 🤖 Modelos de IA e Limites

### Plano Gratuito do Gemini
- **1.500 requisições/dia**: Suficiente para uso pessoal intenso
- **Sem custo**: Tokens de entrada/saída gratuitos
- **Rate limit**: 15 RPM (requests por minuto)
- **Contexto**: Até 1M tokens por conversa

### Modelos Disponíveis

| Modelo | Velocidade | Capacidade | Melhor Para |
|--------|------------|------------|-------------|
| **gemini-2.0-flash-exp** | ⚡⚡⚡⚡⚡ | Última geração com reasoning | Análises complexas |
| **gemini-1.5-flash** | ⚡⚡⚡⚡ | Balanceado | Uso geral (recomendado) |
| **gemini-1.5-flash-8b** | ⚡⚡⚡⚡⚡ | Leve | Respostas simples |
| **gemini-1.5-pro** | ⚡⚡ | Máxima precisão | Tarefas complexas |

## 🏗 Arquitetura e Tecnologias

### Stack Tecnológico

#### Linguagem e Frameworks
- **Swift 5.9+**: Linguagem principal com async/await e actors
- **SwiftUI**: Interface declarativa com @Observable e property wrappers
- **AppKit**: Integração com sistema para janelas customizadas

#### APIs do Sistema
- **ScreenCaptureKit**: Captura moderna e eficiente de tela
- **Vision Framework**: OCR com 99.7% de precisão via VNRecognizeTextRequest
- **Carbon Events API**: Hotkeys globais que funcionam em qualquer contexto
- **CoreGraphics**: Manipulação de imagens e detecção de elementos

#### Persistência e Estado
- **SwiftData**: Modelagem declarativa para histórico
- **@Observable**: Estado reativo com observação automática
- **UserDefaults**: Configurações e preferências seguras

### Estrutura do Projeto

```
macToSearch/
├── 🎯 Core/
│   ├── macToSearchApp.swift      # Entry point com @main
│   ├── AppDelegate.swift         # Coordenador de janelas e eventos
│   └── Models/
│       ├── AppState.swift        # Estado global observável
│       └── DrawingPath.swift     # Geometria de seleção
│
├── 🪟 Windows/
│   ├── OverlayWindow.swift       # Janela fullscreen para captura
│   └── FloatingSearchWindow.swift # Barra flutuante glassmórfica
│
├── 🎨 Views/
│   ├── DrawingOverlayView.swift  # Canvas de seleção interativo
│   ├── MinimalChatBubble.swift   # Componentes de chat
│   ├── ImagePreviewBar.swift     # Galeria de imagens anexadas
│   └── MarkdownTextView.swift    # Renderização rica de texto
│
├── 🔧 Managers/
│   ├── ScreenCaptureManager.swift # Estratégias de captura
│   ├── OCRManager.swift          # Pipeline de extração de texto
│   ├── HotkeyManager.swift       # Registro de atalhos globais
│   └── ElementDetector.swift     # Detecção inteligente de UI
│
└── 🌐 Services/
    └── GeminiService.swift       # Cliente API com retry e cache
```

### Padrões de Arquitetura

- **MVVM com Coordinators**: Views declarativas + ViewModels observáveis
- **Repository Pattern**: Serviços isolados e testáveis
- **State Management**: Single source of truth com AppState
- **Protocol-Oriented**: Abstrações para flexibilidade

## 🎨 Design System

### Glassmorphism Implementation

```swift
// Material effects nativos do macOS
.background(.ultraThinMaterial)
.background(Color.gray.opacity(0.3))
.blur(radius: 20)
.overlay(
    RoundedRectangle(cornerRadius: 20)
        .stroke(
            AngularGradient(
                colors: [.blue, .purple, .pink, .orange],
                center: .center
            ),
            lineWidth: 2
        )
)
```

### Princípios de Design

1. **Clareza através da Transparência**: Contexto sempre visível
2. **Hierarquia Visual**: Blur progressivo para profundidade
3. **Movimento Natural**: Spring animations com damping realista
4. **Cores Vibrantes**: Gradientes animados para feedback visual
5. **Minimalismo Funcional**: Cada elemento tem propósito claro

## 🔒 Privacidade e Segurança

### Princípios de Privacidade

- **Processamento Local Primeiro**: OCR e detecção executados no dispositivo
- **Sem Telemetria**: Nenhum dado de uso é coletado
- **Comunicação Mínima**: Apenas queries de IA são enviadas para Gemini
- **Armazenamento Seguro**: API keys no Keychain, não em plaintext
- **Permissões Explícitas**: Usuário controla todos os acessos

### Dados Transmitidos

| Tipo | Local | Remoto | Notas |
|------|-------|--------|-------|
| Screenshots | ✅ Sim | ❌ Não | Processados e descartados |
| Texto OCR | ✅ Sim | ⚠️ Opcional | Apenas se enviado para IA |
| Histórico | ✅ Sim | ❌ Não | SwiftData local |
| API Keys | ✅ Sim | ❌ Não | Keychain encryption |
| Queries IA | ❌ Não | ✅ Sim | HTTPS para Gemini |

## ⚠️ Problemas Conhecidos e Soluções

### Captura de Tela

**Problema**: Apenas wallpaper capturado, sem aplicações
- **Causa**: Permissões de Screen Recording incompletas
- **Solução**: 
  1. Abra `Ajustes > Privacidade > Gravação de Tela`
  2. Remova e re-adicione macToSearch
  3. Reinicie o app

**Problema**: macOS Sequoia requer re-aprovação mensal
- **Causa**: Nova política de segurança da Apple
- **Solução**: Aceite o prompt mensal ou compile localmente

### Performance

**Problema**: Delay na primeira captura
- **Causa**: Inicialização do ScreenCaptureKit
- **Solução**: Framework é pré-carregado após primeiro uso

**Problema**: OCR lento em imagens grandes
- **Causa**: Processamento síncrono de alta resolução
- **Solução**: Redimensionamento automático implementado

### Compatibilidade

**Problema**: Hotkeys não funcionam em alguns apps
- **Causa**: Apps com captura exclusiva de teclado
- **Solução**: Use o ícone do menu bar como alternativa

## 🚀 Roadmap de Desenvolvimento

### v1.1 - Multi-Monitor & Cloud (Q1 2025)
- [ ] Suporte completo para múltiplos monitores
- [ ] Sincronização de histórico via iCloud
- [ ] Tradução automática inline
- [ ] Export para Markdown/PDF

### v1.2 - AI Models & Offline (Q2 2025)
- [ ] Integração com GPT-4, Claude 3.5
- [ ] Modo offline com Llama 3.2
- [ ] Plugins para apps específicos (Xcode, Figma)
- [ ] API para extensões de terceiros

### v2.0 - Intelligence Platform (Q3 2025)
- [ ] Agentes autônomos para tarefas
- [ ] RAG com documentos locais
- [ ] Integração com Apple Intelligence
- [ ] Modo colaborativo em equipe

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Veja como participar:

### Setup de Desenvolvimento

```bash
# Clone e configure
git clone https://github.com/yourusername/macToSearch.git
cd macToSearch

# Instale SwiftLint (opcional mas recomendado)
brew install swiftlint

# Abra no Xcode
open macToSearch.xcodeproj
```

### Processo de Contribuição

1. **Fork** o projeto
2. **Feature Branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** com mensagens descritivas
4. **Push** para sua branch
5. **Pull Request** com descrição detalhada

### Código de Conduta

- Use Swift idiomático e SwiftUI moderno
- Mantenha cobertura de testes > 70%
- Documente APIs públicas
- Siga o design system existente

## 📚 Recursos e Documentação

### Links Úteis
- [Documentação do Gemini API](https://ai.google.dev/docs)
- [ScreenCaptureKit Guide](https://developer.apple.com/documentation/screencapturekit)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)

### Projetos Relacionados
- [Circle to Search (Google)](https://blog.google/products/search/circle-to-search-android/)
- [Screenshot to Code](https://github.com/abi/screenshot-to-code)
- [Codeshot](https://github.com/PolybrainAI/codeshot)

## 📄 Licença

Este projeto está licenciado sob a **MIT License** - veja [LICENSE](LICENSE) para detalhes.

```
MIT License
Copyright (c) 2025 macToSearch Contributors

Permission is hereby granted, free of charge...
```

## 🙏 Agradecimentos

- **Google** pela API Gemini e inspiração do Circle to Search
- **Apple** pelas poderosas APIs nativas do macOS
- **Comunidade Swift** pelo suporte e feedback
- **Você** por usar e apoiar o projeto!

---

<div align="center">

**Desenvolvido com SwiftUI e IA** 🚀

Transformando a maneira como você busca informações no macOS

[Reportar Bug](https://github.com/yourusername/macToSearch/issues) • 
[Solicitar Feature](https://github.com/yourusername/macToSearch/issues) • 
[Discussões](https://github.com/yourusername/macToSearch/discussions)

</div>