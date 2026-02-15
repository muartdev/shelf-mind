# Mind Shelf Widget

Widget Extension kurulumu tamamlandı.

## Yapılanlar

- `MindShelfWidget.swift` – unread count, total count, recent bookmarks (Small + Medium)
- `MindShelfWidgetBundle.swift` – entry point (@main)
- `MindShelfWidget.entitlements` – App Group (`group.com.muartdev.mind`)

## Nasıl Çalışır

- `WidgetDataManager` ana uygulamada bookmark verisini app group'a yazıyor
- Widget bu veriyi okuyup Small ve Medium boyutlarda gösteriyor
- Widget'a tıklayınca `mind://bookmarks` ile uygulama açılıyor
