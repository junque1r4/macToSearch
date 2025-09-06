# macToSearch - Histórico de Tentativas de Correção da Captura de Tela

## Problema Principal
O aplicativo macToSearch deveria capturar a tela inteira com todos os aplicativos visíveis (como Xcode, Terminal, etc.) quando o usuário pressiona Command + Shift + Space, similar ao Circle to Search do Google. No entanto, está capturando apenas o papel de parede (wallpaper) sem mostrar os aplicativos abertos.

## Tentativas de Correção Realizadas

### 1. Remoção da Opacidade no DrawingOverlayView
**Arquivo:** `DrawingOverlayView.swift`
**Mudança:** Removemos `.opacity(0.9)` da imagem de fundo
**Resultado:** ❌ Não resolveu - continuou mostrando apenas o wallpaper

### 2. Modificação do SCContentFilter
**Arquivo:** `ScreenCaptureManager.swift` e `ScreenCaptureManagerV2.swift`
**Mudanças tentadas:**
- Adicionamos comentários sobre captura sem transparência
- Configuramos `backgroundColor = .clear`
- Tentamos excluir janelas do próprio app da captura
**Resultado:** ❌ Não resolveu - SCContentFilter falha com erro de permissão TCC

### 3. Minimização da Janela Principal
**Arquivo:** `AppDelegate.swift`
**Mudança:** Tentamos minimizar a janela principal antes da captura com `mainWindow.miniaturize(nil)`
**Resultado:** ❌ Piorou - a tela ficou completamente preta

### 4. Uso de NSApp.hide()
**Arquivo:** `AppDelegate.swift`
**Mudança:** Tentamos esconder o app completamente antes da captura
**Resultado:** ❌ Piorou - apenas o wallpaper apareceu, sem nenhum app

### 5. Remoção Total de Interferências
**Arquivo:** `AppDelegate.swift`
**Mudança:** Removemos todas as tentativas de esconder/minimizar janelas
**Resultado:** ❌ Voltou a mostrar apenas o wallpaper

### 6. Métodos Alternativos de Captura

#### 6.1 CGWindowListCreateImage com Diferentes Opções
**Tentativas:**
```swift
// Tentativa 1 - Básica
CGWindowListCreateImage(screenRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)

// Tentativa 2 - Com múltiplas opções
CGWindowListCreateImage(screenRect, [.optionOnScreenOnly, .optionIncludingWindow], 
                        kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming])

// Tentativa 3 - Com optionAll
CGWindowListCreateImage(screenRect, .optionAll, kCGNullWindowID, .bestResolution)
```
**Resultado:** ❌ Todas capturam apenas o wallpaper

#### 6.2 CGDisplayCreateImage
**Código:**
```swift
let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber ?? 0
CGDisplayCreateImage(displayID.uint32Value)
```
**Resultado:** ❌ Também captura apenas o wallpaper

#### 6.3 SCScreenshotManager (ScreenCaptureKit)
**Problema:** Requer permissão de Screen Recording
**Erro:** "The user declined TCCs for application, window, display capture"
**Resultado:** ❌ Falha devido a permissões

### 7. Configurações de Entitlements e Info.plist
**Verificado:**
- `NSScreenCaptureUsageDescription` está presente
- App Sandbox está desabilitado (`com.apple.security.app-sandbox = 0`)
- Permissões de leitura/escrita estão habilitadas
**Resultado:** ✅ Configurações estão corretas, mas não resolvem o problema

### 8. Ordem de Execução e Timing
**Tentativas:**
- Adicionar delay antes da captura
- Esconder overlay com `orderOut(nil)` antes da captura
- Diferentes tempos de espera (100ms, 200ms, 500ms)
**Resultado:** ❌ Não afetou o resultado

### 9. Métodos de Fallback
**Implementado:** Sistema de fallback com múltiplos métodos de captura em sequência:
1. SCScreenshotManager (falha por permissão)
2. CGWindowListCreateImage (captura apenas wallpaper)
3. CGDisplayCreateImage (captura apenas wallpaper)
**Resultado:** ❌ Todos os métodos falham ou capturam incorretamente

## Problema Atual

### O que funciona:
- ✅ O overlay aparece corretamente
- ✅ O usuário consegue desenhar e selecionar áreas
- ✅ O OCR funciona na área selecionada
- ✅ A integração com Gemini funciona
- ✅ O cropping da imagem funciona corretamente

### O que NÃO funciona:
- ❌ A captura de tela mostra apenas o wallpaper
- ❌ Aplicativos abertos (Xcode, Terminal, etc.) não aparecem na captura
- ❌ CGWindowListCreateImage e CGDisplayCreateImage ambos falham em capturar janelas de aplicativos

## Logs de Debug
```
Trying direct capture...
Direct capture failed: Error Domain=com.apple.ScreenCaptureKit.SCStreamErrorDomain Code=-3801 
"The user declined TCCs for application, window, display capture"
Trying simple screenshot...
Capturing simple screenshot...
CGDisplay capture successful
```

## Possíveis Causas

1. **Problema de Permissões do macOS**: Mesmo com as configurações corretas, o macOS pode estar bloqueando a captura de janelas de outros aplicativos

2. **Problema de Window Server**: As APIs CGWindowList e CGDisplay podem não estar conseguindo acessar o compositor de janelas corretamente

3. **Problema de Timing**: Pode haver uma condição de corrida onde as janelas não estão disponíveis no momento da captura

4. **Limitação da API**: As APIs podem ter mudado no macOS recente e não capturam mais janelas de terceiros sem permissão explícita

### 10. Implementação com ScreenCaptureKit usando Permissão Confirmada
**Arquivo:** `AppDelegate.swift`
**Mudança:** Após confirmar que a permissão de Screen Recording está ativa, implementamos:
```swift
let content = try await SCShareableContent.current
let filter = SCContentFilter(display: display, excludingWindows: [])
let screenshot = try await SCScreenshotManager.captureImage(
    contentFilter: filter,
    configuration: configuration
)
```
**Resultado:** ❌ Ainda captura apenas o wallpaper, mesmo com permissão explícita

### 11. Correção do ESC no Overlay
**Arquivo:** `OverlayWindow.swift`
**Mudança:** Adicionamos override de `keyDown` para capturar ESC (keycode 53)
**Resultado:** ✅ ESC agora funciona corretamente para fechar o overlay

## Status Atual (Após Todas as Tentativas)

### ✅ O que FUNCIONA:
- ESC fecha o overlay corretamente
- Permissão de Screen Recording está ativa no sistema
- O overlay aparece e permite desenho
- OCR e processamento funcionam na área selecionada
- A integração com Gemini funciona

### ❌ O que NÃO FUNCIONA:
- **PROBLEMA PRINCIPAL**: Mesmo com permissão de Screen Recording ativa, todas as APIs de captura (SCScreenshotManager, CGWindowListCreateImage, CGDisplayCreateImage) retornam apenas o wallpaper sem os aplicativos

## Logs de Debug Mais Recentes
```
Trying ScreenCaptureKit with permission...
Found 1 displays and X windows
Using display: 2056x1329
ScreenCaptureKit capture successful!
```
Mas a imagem capturada ainda mostra apenas o wallpaper.

## Possíveis Causas Atualizadas

1. **Bug do macOS**: Pode haver um bug na implementação atual do macOS onde as APIs não respeitam a permissão de Screen Recording corretamente

2. **Problema de Timing com ScreenCaptureKit**: A API pode estar capturando antes das janelas serem compostas

3. **Filtro Incorreto**: O `SCContentFilter` pode precisar de configuração específica para incluir janelas de terceiros

4. **Problema de Composição**: O Window Server pode não estar incluindo as janelas na captura por alguma razão

## Próximos Passos Sugeridos

1. **Listar e Debug Janelas Disponíveis**:
   ```swift
   for window in content.windows {
       print("Window: \(window.title ?? "untitled") - on screen: \(window.isOnScreen)")
   }
   ```

2. **Tentar Captura de Janela Individual**:
   - Em vez de capturar o display inteiro, capturar janelas individuais e compor

3. **Usar Stream em vez de Screenshot**:
   - Criar um SCStream e capturar um frame dele

4. **Verificar Console Logs**:
   - Procurar por erros do WindowServer ou ScreenCaptureKit no Console.app

## Observação Importante
Este é um problema complexo que parece estar relacionado a como o macOS moderno lida com privacidade e captura de tela. Mesmo com todas as permissões corretas, as APIs não estão funcionando como esperado. Isso pode requerer uma abordagem completamente diferente ou aguardar uma correção da Apple.