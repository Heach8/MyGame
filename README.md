# Berenin Adası

Beren ve arkadaşlarının birlikte oynayacağı, haritasını ve avatarını çocukların kendisinin yaptığı 3D ada oyunu. Telefon ve tablet için (Android ve iOS), Godot 4.6 ile yapılıyor.

- Ürün planı: https://claude.ai/artifact/MdZZj8uL1YwtcFfgAgTY5N
- İlk web prototipi: `prototype/web/berenin-adasi.html` (tarayıcıda açılır)

## Şu an oyunda neler var

Ekran görüntüleri her derlemede otomatik alınır: GitHub'da `ekran/main` dalı.

**Aşama 2: avatar**

- Yarı gerçekçi karakterler: insan oranları, dizden ve dirsekten bükülen kollar ve bacaklar, eller, burun, kaş, göz bebeği ve dudaklı yüz; doğal yürüyüş, göz kırpma, nefes alma ve etrafa bakınma (`scripts/avatar.gd`, hepsi kodla üretilir)
- Oyun ilk açıldığında avatar ekranı gelir; sonra sol üstteki **Avatarım** düğmesiyle tekrar açılır
- Seçenekler: ad, ten rengi, saç modeli (kısa, uzun, at kuyruğu, topuz), saç rengi, göz rengi, tişört, pantolon, aksesuar (gözlük, şapka, fiyonk)
- Karakter seçtikçe canlı değişir; avatar tablette `user://avatar.json` olarak saklanır
- Avatar sadece bu ayarlardan oluşur, fotoğraf içermez (`scripts/avatar_data.gd`)
- **Fotoğrafımdan yap:** galeriden fotoğraf seçilir; çocuk sırayla yanağına, saçına ve gözüne dokunur, o noktaların rengine en yakın ten, saç ve göz rengi seçilir. Fotoğraf yalnızca hafızada tutulur, kaydedilmez, gönderilmez ve bitince silinir (`scripts/photo_picker.gd`)

**Aşama 1: temel oyun**

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
4. Yeni bir sürüm eskisinin üstüne kurulur. Sürüm 0.2.0 öncesi bir APK kuruluysa onu bir kez silin, sonra yenisini kurun (eski sürümler farklı bir anahtarla imzalanıyordu). Kurulu sürüm ekranın sol üstünde yazar.

## Bilgisayarda açmak

1. [Godot 4.6.3](https://godotengine.org/download/archive/4.6.3-stable/) indirin.
2. Godot'da **İçe aktar** deyip bu klasördeki `project.godot` dosyasını seçin.
3. Sağ üstteki ▶ düğmesiyle oyunu başlatın.

## Klasörler

| Klasör | İçinde ne var |
| --- | --- |
| `scenes/` | Oyun sahnesi |
| `scripts/` | Oyunun kodu (GDScript) |
| `data/maps/` | Harita dosyaları; harita kurucu bunları yazacak |
| `prototype/web/` | İlk tarayıcı prototipi |
| `tests/` | Hızlı testler (`godot --headless --path . --script res://tests/test_runner.gd`) |
| `.github/workflows/` | Her değişiklikte otomatik kontrol ve Android derlemesi |

## Haritayı elle değiştirmek

`data/maps/baslangic.json` içindeki her satır bir nesne: `t` türü, `x` ve `z` konumu (metre, ada merkezi 0,0), `rot` dönüş (radyan). Türler: `agac`, `cam`, `ev`, `cicek`, `kaya`, `bank`, `lamba`, `havuz`. Ada yarıçapı 36 metre.
