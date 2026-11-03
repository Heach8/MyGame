# Berenin Adası

Beren ve arkadaşlarının birlikte oynayacağı, haritasını ve avatarını çocukların kendisinin yaptığı 3D ada oyunu. Telefon ve tablet için (Android ve iOS), Godot 4 ile yapılıyor.

- Ürün planı: https://claude.ai/artifact/MdZZj8uL1YwtcFfgAgTY5N
- İlk web prototipi: `prototype/web/berenin-adasi.html` (tarayıcıda açılır)

## Şu an oyunda neler var (aşama 1)

- Ada: çimen, kum, deniz, gökyüzü, güneş ışığı ve gölgeler
- Haritadan yüklenen evler, ağaçlar, çiçekler, banklar, lambalar, havuz (`data/maps/baslangic.json`)
- Beren'in karakteri: yürüme, koşma, zıplama
- Adada dolaşan üç arkadaş (çok oyunculu aşamaya kadar bilgisayar yönetiyor)
- Tablet kontrolleri: sol altta joystick, sağ altta Zıpla düğmesi, ekranı sürükleyince kamera döner, iki parmakla yakınlaşır
- Bilgisayarda: W A S D veya oklar, Boşluk (zıpla), Shift (koş), fare tekerleği (yakınlaş)

## Tablete nasıl yüklenir (Android)

1. GitHub'da bu deponun **Actions** sekmesine girin, en son başarılı **Derleme** çalışmasını açın.
2. Sayfanın altındaki **Artifacts** bölümünden `berenin-adasi-android` dosyasını indirin ve zipten çıkarın.
3. `berenin-adasi.apk` dosyasını tablete gönderin (e-posta, Drive, USB) ve açın. Tablet "bilinmeyen kaynaklardan yüklemeye" izin isteyebilir.

## Bilgisayarda açmak

1. [Godot 4.3](https://godotengine.org/download/archive/4.3-stable/) indirin.
2. Godot'da **İçe aktar** deyip bu klasördeki `project.godot` dosyasını seçin.
3. Sağ üstteki ▶ düğmesiyle oyunu başlatın.

## Klasörler

| Klasör | İçinde ne var |
| --- | --- |
| `scenes/` | Oyun sahnesi |
| `scripts/` | Oyunun kodu (GDScript) |
| `data/maps/` | Harita dosyaları; harita kurucu bunları yazacak |
| `prototype/web/` | İlk tarayıcı prototipi |
| `.github/workflows/` | Her değişiklikte otomatik kontrol ve Android derlemesi |

## Haritayı elle değiştirmek

`data/maps/baslangic.json` içindeki her satır bir nesne: `t` türü, `x` ve `z` konumu (metre, ada merkezi 0,0), `rot` dönüş (radyan). Türler: `agac`, `cam`, `ev`, `cicek`, `kaya`, `bank`, `lamba`, `havuz`. Ada yarıçapı 36 metre.
