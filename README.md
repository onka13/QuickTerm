# QuickTerm

Basit ve hafif macOS terminali: üstte sekmeler, sol tarafta kayıtlı komutlar menüsü.

## Özellikler
- **Üst Sekmeler:** `⌘T` ile yeni sekme açma, `⌘W` ile kapatma.
- **Sol Komut Menüsü (`⌘B` ile aç/kapat):**
  - `+` ile yeni komut ekleme (aktif terminal sekmesinin o anki klasörünü otomatik varsayılan alır).
  - Komuta tıklayınca mevcut aktif sekmede çalıştırır.
  - Düzenleme ve onaylı silme.
  - Sürükleyerek sıralama ve arama.
- **Yazı Boyutu:** `⌘+` / `⌘-` ile büyütüp küçültme.

## Derleme ve Çalıştırma
```bash
./scripts/build_app.sh
open dist/QuickTerm.app
```
