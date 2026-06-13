#!/usr/bin/env python3
"""
Kavira Giyotin — SEO topic cluster generator.

Üretilen sayfalar:
  • 8 tedarikçi sayfası → /tedarikci/{slug}
  • 8 konu sayfası → /{slug}

Çağrılma: python3 generate_seo_pages.py [OUTPUT_DIR]
  OUTPUT_DIR varsayılan: /var/www/kaviragiyotin/landing
"""
import sys
import os
from pathlib import Path
from textwrap import dedent
import json

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else "/var/www/kaviragiyotin/landing")
BASE_URL = "https://kaviragiyotin.online"

# ─────────────────────────────────────────────────────────────
# 8 TEDARİKÇİ
# ─────────────────────────────────────────────────────────────
VENDORS = [
    {
        "slug": "katar",
        "name": "Katar Alüminyum",
        "system": "Klasik Giyotin",
        "code_prefix": "K-14",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 149 mm",
        "cam_boy_formul": "(Yükseklik − 263) ÷ 3",
        "profil_sayisi": 12,
        "ornek_profiller": [
            ("K-1401", "Motor Kutusu Alt", "1.293"),
            ("K-1402", "Motor Kutusu Üst", "0.669"),
            ("K-1403", "Alt Kasa", "1.355"),
            ("K-1404", "Yan Ara Dikme", "0.653"),
            ("K-1405", "Yan Ana Dikme", "1.650"),
            ("K-1411", "Kenet Çekme Profili", "0.737"),
            ("K-1412", "Hareketli Üst Küpeşte", "0.366"),
        ],
        "intro": "Katar Alüminyum, Türkiye'de yaygın kullanılan klasik üç panelli giyotin cam sistemleri üreten alüminyum profil tedarikçisidir. K-1401'den K-1412'ye uzanan 12 profil kodlu sistemi, atölyelerin standart cam balkon imalatında en sık tercih ettiği seçeneklerden biridir.",
        "ozellik": "Katar Klasik Giyotin sistemi, motor kutusu üst + alt yapısı, yan kasa, ana ve ara dikmeler, fonksiyonel baza ve kenet çekme profilleriyle 3 hareketli cam paneli desteler. Sistem kayışlı veya zincirli motor seçenekleriyle çalışır.",
        "aksesuar": "Köşe takozu (4 ad), rulman yatağı (2 ad), boru başı kapağı (2 ad), merkezleme takozu (8 ad), kenetli baza kapak (4 ad), cam fitili (EPDM), kapak fitili, kenet fitili.",
    },
    {
        "slug": "saray-gyt80",
        "name": "Saray Mimari Sistemler",
        "system": "GYT-80 Zincirli Giyotin",
        "code_prefix": "145",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 178 mm (yan kasa 89×2)",
        "cam_boy_formul": "(Yükseklik − 295) ÷ 3",
        "profil_sayisi": 12,
        "ornek_profiller": [
            ("14506", "Kasa Kapak Profili", "2.635"),
            ("14507", "Kasa Kapak Profili (Alt)", "0.950"),
            ("14508", "Yatay Alt Kasa", "1.035"),
            ("14509", "Yan Kasa", "1.775"),
            ("14510", "Hareketli Pervaz", "1.225"),
            ("14513", "Yan Kanat Profili", "0.470"),
            ("14515", "Hareketli Ray Profili", "0.850"),
        ],
        "intro": "Saray Mimari Sistemler GYT-80 modeli, 3 kanatlı zincirli giyotin cam balkon sistemi olarak Türkiye'de geniş atölye ağıyla bilinen alüminyum profil ürünüdür. Resmi katalog 14506-14517 arası profil koduyla detaylı imalat listesi sunar.",
        "ozellik": "GYT-80 sisteminde hareketli ray (14515) yükseklik eksenli kesilir (H-145mm × 4 adet) — bu Saray'a özgü tasarım kararıdır. Yan kanat profilleri (14513) (H/3)−29 mm formülüyle 6 adet üretilir. Çıta profili (14517) yükseklik eksenli, 2 adet kesilir.",
        "aksesuar": "SC-930 Zincir dişlisi (2 ad), SC-935 Kanat köşe plastiği (12 ad — her kanat 4 köşe × 3 kanat), SC-936 Denge takozu (12 ad), SC-942 Cam pimi (12 ad), SC-938/939/940 sızdırmazlık ve kıl fitilleri, özel 2.5m zincir × 2 adet.",
    },
    {
        "slug": "zahit-klasik",
        "name": "Zahit Alüminyum",
        "system": "Klasik Giyotin",
        "code_prefix": "V.GY.1",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 250 mm",
        "cam_boy_formul": "(Yükseklik − 280) ÷ 3",
        "profil_sayisi": 14,
        "ornek_profiller": [
            ("V.GY.101", "Ana Dikme", "1.650"),
            ("V.GY.102", "Orta Dikme", "1.136"),
            ("V.GY.100", "Bitiş Dikme", "0.492"),
            ("V.GY.106", "Alt Kasa", "1.295"),
            ("V.GY.108", "Sabit Küpeşte", "0.880"),
            ("V.GY.208", "Hareketli Küpeşte", "0.573"),
            ("V.ES.109", "Kenet Profili", "0.606"),
        ],
        "intro": "Zahit Alüminyum Klasik Giyotin sistemi, V.GY.100-V.GY.110 ve V.ES.103-V.ES.116 serisi profillerle 3 cam panelli standart giyotin imalatı için tasarlanmıştır. Sistem klasik tutamaksız yapıdadır ve kayışlı/zincirli motor seçenekleri sunar.",
        "ozellik": "Zahit Klasik'te ana dikme V.GY.101 (118.7×85mm, 1.650 kg/m) en ağır profildir. Cam çıta profilleri V.ES.103 ve V.ES.104 her cam panelinin 4 köşesine yerleşir (toplam 6 yan + 6 alt = 12 adet kesim). Aksesuar reçetesi GY-01 köşe takozundan GY-24 küpeşte takozuna 12 ana kalem içerir.",
        "aksesuar": "Kasa köşe birleştirme takozu (2 ad), motor tarafı kapak (1 ad), boru başı kapak ve alüminyum (1+1 ad), rulman yatağı (1 ad), merkezleme takozu (8 ad), kenetli baza kapak 2L+2R (4 ad), düz baza kapak (2 ad), küpeşte kapak 1L+1R (2 ad), küpeşte takoz (2 ad).",
    },
    {
        "slug": "zahit-vetrina",
        "name": "Zahit Alüminyum",
        "system": "Vetrina Silinebilir Giyotin",
        "code_prefix": "V.GY.2",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 250 mm",
        "cam_boy_formul": "(Yükseklik − 290) ÷ 3",
        "profil_sayisi": 15,
        "ornek_profiller": [
            ("V.GY.104", "Motor Kapak Profili", "2.430"),
            ("V.GY.105", "Motor Kapak Kapatma", "0.837"),
            ("V.GY.103", "Dikey Baza Profili", "0.706"),
            ("V.GY.205", "Alt Kasa", "1.561"),
            ("V.GY.206", "Tutamaklı Baza", "0.890"),
            ("V.GY.111", "Damlalık Profili", "0.237"),
            ("V.GY.204", "Vasistas Kasa", "0.342"),
        ],
        "intro": "Zahit Vetrina Silinebilir Giyotin, alt panelin tutamaklı baza ve vasistas mekanizmasıyla içe doğru açılarak temizlenebilen premium giyotin sistemidir. V.GY.2XX serisi profillerle, klasik sisteme ek olarak vasistas kasası, tutamaklı baza ve damlalık profilleri içerir.",
        "ozellik": "Vetrina'nın 'silinebilir' özelliği alt panelin GY-25 vasistas kol ve GY-26 vasistas makas ile içe açılmasından gelir. Motor kapağı V.GY.104 (2.430 kg/m) sistemdeki en ağır profildir. Damlalık profili V.GY.111 (0.237 kg/m) yağmur suyunun motor kutusuna girmesini engeller.",
        "aksesuar": "Klasik aksesuarlar + GY-19/20 vasistas alt takoz ve alt kasa takoz (1L+1R = 2'şer ad), GY-21 tutamaklı baza kapak (2), GY-22 vasistas üst kapak 1L+1R (2), GY-23 orta vasistas alt kasa takoz (2), GY-24 küpeşte takoz (2), GY-25 vasistas kol (2), GY-26 vasistas makas (2), GY-27 ispanyolet kilit (2).",
    },
    {
        "slug": "asistal-g130t",
        "name": "Asistal Alüminyum",
        "system": "G130T Isıcamlı Giyotin",
        "code_prefix": "G130T",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 170 mm",
        "cam_boy_formul": "(Yükseklik − 290) ÷ 3",
        "profil_sayisi": 13,
        "ornek_profiller": [
            ("G130T 01", "Üst Kasa Profili", "2.152"),
            ("G130T 02", "Yan Kasa Profili", "2.054"),
            ("G130T 03", "Alt Kasa Profili", "1.713"),
            ("G130T 11", "Kanat Profili", "0.941"),
            ("G130T 12", "Takviyeli Kanat Profili", "1.275"),
            ("G130T 13", "Kanat Profili (Ana)", "1.076"),
            ("G130T 08", "Tek Cam Çıta", "0.277"),
        ],
        "intro": "Asistal G130T, ısıcamlı (çift cam) dikey sürme cam balkon sistemi olarak Türkiye'de premium segmentte yer alan giyotin profil sistemidir. 13 profil koduyla (G130T 01-13) hem ısı yalıtımı hem estetik sunar.",
        "ozellik": "G130T sisteminde kanat profili olarak FW ≤ 3200mm için G130T 11 (0.941 kg/m), FW > 3200mm için takviyeli G130T 12 (1.275 kg/m) kullanılır. Yan dikme G130T 13 (1.076 kg/m) her cam panelinin 2 yan tarafında, toplam 6 adet kesilir. Motor borusu G100-A12 galvaniz sekizgendir.",
        "aksesuar": "PVC kapak takımı (EM-G130-TK), rulman yatağı (EM125-23-1), giyotin tambur başı (G100-A11-3), motor yan sacı (G130T-A1), zincir kılavuz yüzüğü (G130-A01), ispanyolet 400mm (ASI-MP-ES 400), vasistas makas multi-point (ASI-V 0501), çift yönlü kilitleme kolu (FDA-K 01), KF 67-650/1000 fırça fitili, MO-60 kenet bini fitili.",
    },
    {
        "slug": "tema",
        "name": "Tema Alüminyum",
        "system": "Isı Camlı Giyotin (T.24XX serisi)",
        "code_prefix": "T.24",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 175 mm",
        "cam_boy_formul": "(Yükseklik − 295) ÷ 3",
        "profil_sayisi": 20,
        "ornek_profiller": [
            ("T.2401", "Üst Kutu Şase", "3.182"),
            ("T.2402", "Üst Kutu Kapak", "0.915"),
            ("T.2450", "Alt Kasa", "1.132"),
            ("T.2455", "Kenet Çekme", "1.007"),
            ("T.2468", "Vasistas Profili", "1.346"),
            ("T.2495", "Kanat Sabitleme", "1.777"),
            ("T.2499", "Yan Profil", "0.530"),
        ],
        "intro": "Tema Alüminyum Isı Camlı Giyotin, 20 profil kodlu (T.2401-T.2499) çift vasistaslı sistemiyle Türkiye'nin köklü alüminyum üreticilerinden Tema'nın premium serisidir. Sistemde 1. ve 2. kanat içeri açılabilir (silinebilir) yapıdadır.",
        "ozellik": "T.2401 üst kutu şase (3.182 kg/m, 116.5×147.6 mm) sistemdeki en ağır profildir. Sistem çift vasistas mantığıyla çalışır: 1. kanat (alt) T.2493 üst+alt kapakla, 2. kanat T.2495 sabitlemeyle içe açılır. Kanat yan profilleri T.2490 + T.2491 çiftli olarak her cam panelinin 2 yan tarafında kullanılır.",
        "aksesuar": "Üst kutu (şase) kapağı 2 ad, rulman yatağı 1 ad, hareketli üst küpeşte kapağı, kanat köşe kapağı 12 ad, köşe takozu 2 ad (sağ-sol), yarım U ve alın bağlantı aparatı 2 ad, T.2493 üst/alt kapağı 2'şer ad, T.2495 1. ve 2. kanat sabitleme 2'şer ad, T.2491 alt kapağı 2 ad, kayış ve zincir bağlantı aparatı, kanat rulmanı 4 ad, vasistas makası 2 ad, kol 2 ad, motor (120Nm-140Nm), motor kumandası.",
    },
    {
        "slug": "mavera",
        "name": "Mavera Mimarlık (MVR)",
        "system": "Giyotin Cam Sistemi (Isı Cam + Tek Cam)",
        "code_prefix": "TG/KIF",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 200 mm",
        "cam_boy_formul": "(Yükseklik − 280) ÷ 3",
        "profil_sayisi": 13,
        "ornek_profiller": [
            ("KIF-0001", "Ana Şase", "2.295"),
            ("KIF-0002", "Şase Kapak", "2.166"),
            ("TG-104", "Yan Kasa Üst", "2.190"),
            ("TG-103", "Yan Kasa Alt", "1.169"),
            ("TGI-107", "Açılır Cam Baza (Isı Cam)", "0.886"),
            ("TGI-106", "Kenet (Isı Cam)", "0.913"),
            ("TGI-105", "Baza (Isı Cam)", "0.629"),
        ],
        "intro": "Mavera Mimarlık (MVR) Giyotin Cam Sistemi, hem 4+12+4 ısı cam hem 8mm tek cam alternatifleriyle sunulan modern giyotin sistemidir. İstanbul ve Konya merkezli proje tabanlı imalat yapan firmanın ürün kataloğunda yer alır.",
        "ozellik": "Mavera sisteminde KIF-0001 ana şase (2.295 kg/m) ve KIF-0002 şase kapak (2.166 kg/m) motor kutusunu oluşturur. Yan kasa iki parçalıdır: alt (TG-103, 1.169 kg/m) + üst (TG-104, 2.190 kg/m). Cam paneli profilleri ısı cam için TGI-105/106/107, tek cam için TCT-105/106/107 alternatifiyle 2/3/4 panel destekler.",
        "aksesuar": "Kasa köşe takozu (4 ad), rulman yatağı (2 ad), boru başı sekizgen demir (2 ad), merkezleme takozu (6 ad), vasistas açılır baza takozu (2 ad), baza kapak PVC (4 ad), cam fitili EPDM, kapak fitili, fırça fitili, kenet fitili.",
    },
    {
        "slug": "tumen-giart",
        "name": "Tümen Alüminyum",
        "system": "GI-ART Giyotin Cam Sistemi",
        "code_prefix": "G-29",
        "panel_count": 3,
        "cam_en_formul": "Genişlik − 240 mm",
        "cam_boy_formul": "(Yükseklik − 300) ÷ 3",
        "profil_sayisi": 14,
        "ornek_profiller": [
            ("G-2924", "Motor Şase", "2.946"),
            ("G-2922", "Yan Kasa", "2.100"),
            ("G-2918", "Şase Kapak", "0.881"),
            ("G-2912", "Alt Kasa", "1.450"),
            ("G-2917", "Tutamaklı Çekme", "1.266"),
            ("G-2916", "Kilit Baza", "1.306"),
            ("G-2926", "Motor Borusu (Alüminyum Ø57.9)", "1.209"),
        ],
        "intro": "Tümen Alüminyum GI-ART, Ankara merkezli üretimle hem klasik (tutamaksız) hem temizlenebilir (tutamaklı) varyantlarıyla sunulan giyotin cam sistemidir. Diğer tedarikçilerden farkı motor borusunun alüminyum (G-2926, 1.209 kg/m) olmasıdır — galvaniz çelik değil.",
        "ozellik": "GI-ART'ın en ayırt edici özelliği alüminyum motor borusudur. G-2924 motor şase (2.946 kg/m, 127×165mm) sistem motor kutusunu oluşturur. Yan kasa G-2922 (2.100 kg/m, 119.5×94.9mm) sistemin yan dikmesidir. Sistem kayışlı veya zincirli motorla çalışır.",
        "aksesuar": "20 ana aksesuar (GI-ART-A-1 ÷ GI-ART-A-20): Şase kapak 1L+1R, zincir boğma, alt kasa köşe takozu, küpeşte kapak, 2. cam üst profil, alt cam üst tutamaklı, push kol (GI-ART-A-11), vasistas makas, boru başı milli, altıgen kasnak, ispanyolet, ispanyolet karşılığı zamak, motor lazeri, boru başı lazer, kayış bağlama. Klasik versiyonda push kol ve vasistas makas yer almaz.",
    },
]

# ─────────────────────────────────────────────────────────────
# 8 KONU (genel rehber sayfaları)
# ─────────────────────────────────────────────────────────────
TOPICS = [
    {
        "slug": "giyotin-nedir",
        "title": "Giyotin Cam Sistemi Nedir? Çalışma Prensibi ve Avantajları",
        "desc": "Giyotin cam sistemi nedir, nasıl çalışır, klasik cam balkon sistemlerinden farkı nedir? Sistemde kullanılan profil yapısı, motor mekanizması, cam tipleri ve montaj prensipleri.",
        "h1": "Giyotin Cam Sistemi Nedir?",
        "anahtarlar": ["giyotin cam sistemi", "giyotin nedir", "dikey sürme cam balkon"],
        "bolumler": [
            ("Giyotin Cam Sisteminin Tanımı", "Giyotin cam sistemi, cam panellerin dikey eksende yukarı kaydırılarak balkon veya teras alanlarının istenildiği gibi açık veya kapalı tutulmasını sağlayan motorlu alüminyum profil sistemidir. Adını giyotin mekanizmasından alan sistem, üst kısımda yer alan motor kutusunun içine sarılan kayış veya zincir aracılığıyla cam panelleri dikey olarak hareket ettirir. Cam paneller tamamen yukarı kaldırıldığında balkon tamamen açık, yarı yarıya indirildiğinde rüzgar kırıcı görevi gören yarı açık, tamamen indirildiğinde ise kapalı (yağmur ve rüzgardan tam korumalı) konuma gelir."),
            ("Klasik Cam Balkon Sistemlerinden Farkı", "Klasik katlanır cam balkon sistemlerinde paneller yan yana açılarak köşeye toplanır, bu da balkon genişliğinin bir kısmının paneller tarafından kaplanmasına yol açar. Giyotin sistemde paneller dikey hareket ettiği için balkon görüş alanı tamamen açık kalır, manzara kesintisiz görülür. Ayrıca giyotin sistemde uzaktan kumanda ile çalıştırma, otomatik durdurma, motorlu eşik takozu ve farklı seviyelerde sabitleme gibi modern özellikler standarttır."),
            ("Sistemin Ana Bileşenleri", "Bir giyotin cam sistemi 4 ana grup parçadan oluşur: 1) Üst motor kutusu (kasa kapak, şase, motor borusu), 2) Yan kasa profilleri (rayları taşır), 3) Hareketli cam panel profilleri (üst kanat, orta kanat, alt kanat), 4) Alt kasa ve baza profilleri. Tüm bu parçalar 6063 veya 6060 alüminyum alaşımından ekstrüde profillerdir. Bağlantı aksesuarları arasında köşe takozları, rulman yatakları, boru başları, fitiller (cam, kenet, fırça, flock, kapak) ve elektrikli aksamlar (motor, kumanda, dişli, kasnak) yer alır."),
            ("Cam Tipi Seçenekleri", "Giyotin sistemler standart olarak iki cam tipinde uygulanır: 8mm tek temperli cam veya 4+12+4 / 4+16+4 kombinasyonlu çift cam (ısı cam). Tek cam sistemler maliyet açısından ekonomik olup zemin kat ve tropikal iklimlerde tercih edilir. Isıcamlı sistemler ise ısı ve ses yalıtımı sağlar, soğuk iklimlerde ve üst katlarda daha uygundur. Sistem tasarımı ısıcama göre yapıldığında profil setleri farklılaşır — kanat profilleri ve cam baza profilleri ısı cam kalınlığına göre üretilir."),
            ("Motor ve Hareket Mekanizması", "Giyotin sistemde dikey hareket için üç farklı mekanizma kullanılır: 1) Zincirli sistem — sağ ve sol kenarda paslanmaz çelik zincir motora bağlı dişlilerle yukarı/aşağı hareket eder, en sessiz çalışan tiptir. 2) Kayışlı sistem — triger dişli kayışı motor kasnağı aracılığıyla cam panelleri taşır, daha ekonomiktir. 3) Manuel sistem — küçük balkonlarda nadiren kullanılan, gaz pistonlu manuel açma sistemi. Türkiye'de yaygın olan motorlu sistemlerde 120Nm-140Nm tüp motor + 433MHz kumanda kullanılır."),
            ("Hangi Mekanlarda Kullanılır", "Giyotin cam sistemleri konut balkonları, teras kapatma, kafe ve restoran ön cepheleri, otel terasları, ofis binaları, alışveriş merkezi vitrin yaklaşımları, villa winter garden ve havuz kenarı pergola sistemlerinde kullanılır. Maksimum genişlik tedarikçiye göre 3500-4500mm, maksimum yükseklik 3000-3500mm arasında değişir. Daha büyük açıklıklar için takviyeli kanat profilleri (örn. Asistal G130T 12) tercih edilir."),
        ],
        "faq": [
            ("Giyotin cam sistemi ne kadar dayanıklıdır?", "Kaliteli üreticiden alınan giyotin cam sistemi 15-20 yıl dayanıklılık sunar. Alüminyum profiller paslanmaz, motor ortalama 30.000 açma-kapama döngüsü garanti eder."),
            ("Giyotin cam sistemine elektrik kesintisi sırasında ne olur?", "Elektrik kesildiğinde sistem son konumda durur, manuel acil durum koluyla aşağı indirilebilir. Bazı premium sistemlerde aküli yedek motor seçeneği bulunur."),
            ("Giyotin sistem yağmur sızdırır mı?", "Doğru montaj edilmiş sistemde alt kasaya entegre drenaj kanalı ve damlalık profili (örn. Zahit V.GY.111) sayesinde yağmur suyu dışarıya yönlendirilir, içeri sızmaz."),
        ],
    },
    {
        "slug": "giyotin-fiyat-hesaplama",
        "title": "Giyotin Cam Fiyatı Nasıl Hesaplanır? Adım Adım Maliyet Rehberi",
        "desc": "Giyotin cam balkon fiyatı nasıl hesaplanır? Alüminyum profil kg, cam m², motor sistemi, aksesuar reçetesi, işçilik ve kâr marjı dahil tam maliyet kalemleri ve hesaplama formülleri.",
        "h1": "Giyotin Cam Fiyatı Nasıl Hesaplanır?",
        "anahtarlar": ["giyotin cam fiyatı", "giyotin maliyet hesaplama", "giyotin fiyat hesaplama"],
        "bolumler": [
            ("Maliyet Kalemlerinin Yapısı", "Giyotin cam sisteminin gerçek maliyeti 6 ana kalemden oluşur: 1) Alüminyum profil (kg × TL/kg), 2) Cam (m² × TL/m²), 3) Motor borusu (m × TL/m) — galvaniz çelik veya alüminyum tipine göre, 4) Mekanik aksesuar (adet × TL/adet), 5) Fitil ve sızdırmazlık (m × TL/m), 6) İşçilik (sistem başı sabit ücret). Bu kalemlerin toplamı net maliyeti verir; üzerine genel gider yüzdesi, kâr marjı ve KDV eklenerek müşteri satış fiyatı çıkar."),
            ("Alüminyum Profil Maliyeti Hesabı", "Her giyotin tedarikçisinin kendine özgü profil seti vardır (örn. Katar 12 profil, Tema 20 profil, Tümen 14 profil). Her profilin kesim ölçüsü tedarikçinin imalat listesinden alınır (örn. Saray GYT-80'de hareketli ray = H-145mm × 4 adet). Bu uzunluk × adet × profil kg/m değeriyle (Tema T.2401 için 3.182 kg/m, Katar K-1405 için 1.650 kg/m gibi) çarpılarak toplam alüminyum kg bulunur. Toplam kg × güncel alüminyum TL/kg fiyatı (2026 ortalama 350-400 TL/kg) alüminyum maliyetini verir."),
            ("Cam Maliyeti Hesabı", "Cam paneli alanı (cam_en × cam_boy ÷ 1.000.000) m² cinsindendir. Her tedarikçinin kendi cam ölçü formülü vardır: Katar cam_en = Genişlik − 149mm, Saray cam_en = Genişlik − 178mm, Asistal G130T cam_en = Genişlik − 170mm. Cam yüksekliği genellikle (Yükseklik − 263 ile 295 arası) ÷ 3 formülüyle hesaplanır (3 cam paneli için). Toplam cam alanı (3 panel × sistem adedi) × TL/m² ile çarpılarak cam maliyeti elde edilir. 2026 ortalama 4+12+4 ısıcam fiyatı 1850-2000 TL/m², 8mm tek cam 950-1100 TL/m²."),
            ("Aksesuar Reçetesi ve Hesabı", "Aksesuarlar adet veya metre cinsinden hesaplanır. Adet bazlı: köşe takozu (2-4 adet/sistem), rulman yatağı (1-2 adet), motor (1 adet), kumanda (1 adet), vasistas makas (silinebilir sistemde 2 adet), ispanyolet (2 adet). Metre bazlı: cam fitili (cam çevresi × cam adedi), kıl fitil (kanat yüksekliği × 12 adet — Saray örneği), kenet fitili. Aksesuar adetleri tedarikçi kataloğundan bire bir alınır; örneğin Saray SC-935 Kanat Köşe Plastiği her sistem için tam 12 adettir."),
            ("Motor Borusu — Önemli Bir Detay", "Motor borusu birçok hesaplama programında unutulan kritik bir kalemdir. Çoğu tedarikçide motor borusu galvaniz çelik (paslanmaz sekizgen, 7mm paket halinde) ve metre fiyatlıdır — 2026'da ortalama 200-220 TL/m. Tümen GI-ART'ta ise motor borusu alüminyum G-2926 (1.209 kg/m) profilidir ve kg fiyatıyla hesaplanır. Sistem genişliğine göre yaklaşık (Genişlik − 75mm) ile (Genişlik − 90mm) arası uzunlukta 1 adet motor borusu her sisteme girer."),
            ("Genel Gider, Kâr ve KDV", "Net malzeme + motor + aksesuar + işçilik toplamına genel gider yüzdesi (%2.5-5) eklenir — bu ofis, elektrik, sarf malzeme giderlerini karşılar. Üzerine atölyenin kâr marjı (%25-40 yaygın) eklenerek satış (KDV hariç) fiyatı bulunur. Son olarak %20 KDV eklenerek müşteriye verilecek nihai satış fiyatı çıkar. Kavira Giyotin programı tüm bu katmanları otomatik hesaplar, kullanıcı sadece güncel birim fiyatları girer."),
        ],
        "faq": [
            ("Giyotin cam m² fiyatı 2026'da ne kadar?", "Ortalama m² fiyatı standart 3000×3000mm pencere için ısıcamlı sistemde 12.000-18.000 TL/m² arası (tedarikçi, motor tipi ve cam kalınlığına göre değişir)."),
            ("Tek cam ile ısı camlı giyotin arasında fiyat farkı nedir?", "Cam maliyeti tek cam sistemde m² başına yaklaşık 800-900 TL daha düşüktür. Profil setleri benzer olduğundan toplam sistemde %15-20 fiyat farkı olur."),
            ("Atölyenin kâr marjı kaç olmalı?", "Sektör standardı %30-35 kâr marjıdır. Daha düşük marjlar sürdürülebilir değildir; daha yüksek marjlar müşteri kaybına yol açabilir."),
        ],
    },
    {
        "slug": "giyotin-kesim-plani",
        "title": "Giyotin Profil Kesim Planı Nasıl Çıkarılır? Bin-Packing Optimizasyonu",
        "desc": "Giyotin cam profil kesim planı, 6500mm stok boyundan en az fire ile kesim, First-Fit Decreasing bin-packing algoritması ve çoklu proje birleştirme ile %30'a varan profil tasarrufu.",
        "h1": "Giyotin Profil Kesim Planı Nasıl Çıkarılır?",
        "anahtarlar": ["giyotin kesim planı", "giyotin profil kesim", "kesim planı optimizasyonu"],
        "bolumler": [
            ("Kesim Planının Önemi", "Giyotin cam imalatında alüminyum profil maliyeti toplam giderin %30-40'ını oluşturur. Bu nedenle profil firesinin minimize edilmesi atölyenin kârlılığını doğrudan etkiler. Standart alüminyum profil 6500mm (bazı tedarikçilerde 6000mm) boylarda stoklanır. İmalat sırasında her profil için gereken parçalar bu stok boyundan kesilir — kalan kısımlar (eğer kullanılmaya uygun değilse) fire olur. İyi bir kesim planı stok boylarını mümkün olduğunca dolu kullanır."),
            ("Bin-Packing Algoritması Nedir?", "Bin-packing (kutu paketleme), belirli bir boya sahip nesneleri (parçalar) sabit hacimli kutulara (stok boyları) yerleştirme problemidir. Giyotin imalatında her profil kodu için bin-packing problemini ayrı çözmek gerekir — çünkü farklı profil kodları birleştirilemez. En yaygın yaklaşım First-Fit Decreasing (FFD) algoritmasıdır: parçalar uzunluğa göre büyükten küçüğe sıralanır, her parça karşılaşılan ilk uygun kutuya yerleştirilir, sığmazsa yeni kutu açılır. FFD optimum sonuca %22 yakın çözüm üretir."),
            ("Bıçak Fire Payı", "Endüstriyel alüminyum kesim makinelerinde bıçak kalınlığı 3-5mm arasındadır; her kesim bu kadar firenin oluşmasına yol açar. Doğru kesim planında bıçak payı hesaba katılır: 10 parçalı bir kesim için 9 bıçak kesimi yapılır (toplam 9×4mm = 36mm fire) + son parça artığı. Kavira Giyotin programı bıçak firesini varsayılan 5mm alır, kullanıcı tedarikçi makinesine göre değiştirebilir."),
            ("Çoklu Proje Birleştirme — %30 Tasarruf", "Tek bir proje için çıkarılan kesim planı genellikle her profil tipinde yarım dolu kutular bırakır — örneğin K-1405 yan dikme için 1 stoktan 2 parça kesildiğinde kalan 3500mm fire olur. Ancak aynı atölyede 3-5 farklı proje varsa, tüm projelerin parçaları birleştirilerek kesim yapılırsa bu yarım kalan kutular doldurularak %25-31 profil tasarrufu sağlanır. Kavira Giyotin'in 'birleşik kesim' özelliği bu mantıkla çalışır: kullanıcı hangi projeleri birleştirmek istediğini seçer, sistem tüm parçaları havuza alıp tek seferde optimize eder."),
            ("Kesim Planının Atölyeye Aktarılması", "Optimize edilmiş kesim planı atölyeye PDF veya yazıcı çıktısı olarak aktarılır. İyi bir kesim listesi şu bilgileri içerir: 1) Profil kodu ve toplam stok adedi, 2) Her stoktaki parça sıralaması (genişlik × adet × hangi projeden), 3) Her stokun fire miktarı, 4) Renk kodu veya proje numarası ile parçaların hangi projeye gideceğinin işaretlenmesi. Kavira Giyotin PDF çıktısında her stok farklı renkle gösterilir ve atölyede karışıklık olmaz."),
            ("Stok Boyu ve Tedarikçi Farkları", "Tüm tedarikçilerde standart 6500mm profil stoğu kullanılır. Bunun istisnası motor borusudur: tedarikçinin galvaniz çelik motor borusu genellikle 7000mm paketten alınır. Tümen GI-ART'ta motor borusu alüminyum olduğu için diğer profillerle birlikte bin-packing'e girer ve 6500mm stoktan kesilir."),
        ],
        "faq": [
            ("Ortalama fire oranı ne kadar olmalı?", "Tek proje için %15-20, çoklu birleşik kesim için %5-10 fire normaldir. %25 üzerindeki fire kesim planının yeniden yapılandırılması gerektiğini gösterir."),
            ("Bin-packing optimizasyonu manuel yapılabilir mi?", "Küçük projelerde (1-2 sistem) Excel ile manuel mümkündür ama 3+ proje birleştiğinde kombinasyon sayısı binlere çıkar ve manuel optimize imkansız hale gelir."),
            ("Kesim planında kullanılmayan kısa parçalar nasıl değerlendirilir?", "200mm altındaki parçalar yapısal olarak kullanılamaz, hurda olarak ayrılır. 200-500mm arası parçalar küçük cam çıta veya kapak için saklanabilir. Kavira Giyotin 200mm altı parçaları otomatik uyarı verir."),
        ],
    },
    {
        "slug": "giyotin-imalat-rehberi",
        "title": "Giyotin Cam Üretim ve İmalat Rehberi: Adım Adım Süreç",
        "desc": "Giyotin cam imalatı adım adım: ölçü alma, profil hesabı, kesim, montaj, cam yerleştirme, motor kurulumu, test ve teslimat. Atölyeler için profesyonel imalat rehberi.",
        "h1": "Giyotin Cam Üretim ve İmalat Rehberi",
        "anahtarlar": ["giyotin imalatı", "giyotin üretimi", "giyotin montaj"],
        "bolumler": [
            ("1. Ölçü Alma ve Müşteri İstekleri", "İmalat öncesi balkon veya teras alanının tam ölçüsü alınır: net genişlik (mm), net yükseklik (mm), ölçü alınan zemin durumu (taşıyıcı betonun dikliği, balkon ön kornişin geometrisi). Müşteriyle cam tipi (8mm tek cam veya 4+12+4 ısı cam), motor tipi (zincirli/kayışlı), kumanda tipi (tekli/çoklu), renk seçeneği (beyaz, antrasit, ahşap görünümlü) konuşulur. Tedarikçi seçimi (Katar, Saray, Zahit, Asistal, Tema, Mavera, Tümen) genellikle atölyenin standart çalıştığı firmaya göre belirlenir."),
            ("2. Profil Hesabı ve Kesim Listesi", "Ölçüler alındıktan sonra tedarikçinin imalat formüllerine göre her profilin kesim ölçüsü çıkarılır. Örneğin Saray GYT-80'de Genişlik=3000mm, Yükseklik=3000mm için: 14506 Kasa Kapak = Genişlik − 12 = 2988mm × 1 ad, 14509 Yan Kasa = Yükseklik − 145 = 2855mm × 2 ad, 14515 Hareketli Ray = Yükseklik − 145 = 2855mm × 4 ad, 14513 Yan Kanat = (Yükseklik÷3) − 29 = 971mm × 6 ad gibi. Tüm parçalar Kavira Giyotin gibi programlarla otomatik çıkar, kesim planı PDF olarak atölyeye gönderilir."),
            ("3. Kesim ve Frezeleme", "Kesim listesindeki parçalar tedarikçiden gelen 6500mm boyutlu stoktan otomatik açı kesim makinesinde 90° kesilir. Kesim sırasında bıçak fire payı (4-5mm) hesaba katılır. Bazı kanat profilleri (örn. Saray 14513 yan kanat) montaj öncesi frezeleme gerektirir — pim deliği, kilit yuvası gibi mekanik işlemler CNC makinede yapılır. Kavira Giyotin kesim planı PDF çıktısında frezeleme gerektiren parçalar işaretlenir."),
            ("4. Yan Kasa ve Üst Motor Kutusu Montajı", "Yan kasa profilleri (Saray 14509 veya Zahit V.GY.101) üst kasa ve alt kasaya köşe takozlarıyla bağlanır. Köşe takozları PVC veya alüminyum dökümdür; her köşede 1 takoz + 4-6 imalat vidası kullanılır. Üst kasa içine motor borusu (alüminyum veya galvaniz çelik) tambur ve rulman yatağıyla yerleştirilir. Motor borusunun bir ucunda dişli (zincirli sistemlerde) veya kasnak (kayışlı sistemlerde) takılı olur."),
            ("5. Cam Paneli Yerleştirme", "Cam paneller dikey çerçevelerine (kanat profilleri T.2491 veya G130T 11) cam fitili (EPDM) ile yerleştirilir. Cam çıta profilleri (V.ES.103/104 veya G130T 08) cam paneli içeriden sıkıştırır. Isı camlı sistemlerde cam paneli alt kenarı drenaj kanalına oturur, böylece su sızması engellenir. Her cam panel hareket etmeden önce yan kasalardaki ray sistemine teker veya rulman ile bağlanır."),
            ("6. Motor ve Zincir/Kayış Bağlantısı", "Motor tüp tipinde, 120Nm-140Nm gücünde, dahili limit switch'li model standarttır. Motor borusunun içine yerleştirilir, dış ucunda zincir dişlisi veya kayış kasnağı bulunur. Zincirli sistemlerde paslanmaz çelik 2×2.5m zincir cam panelin sağ ve sol kenarına bağlanır; alt ucu hareketli kanada, üst ucu motor dişlisine sabitlenir. Kayışlı sistemlerde aynı işi triger dişli kayış görür. Sistem ilk açılıp kapatma yapıldığında limit switch'ler ayarlanır."),
            ("7. Test, Sızdırmazlık ve Teslimat", "Sistem 3-5 tam açma kapama döngüsü ile test edilir. Hareket sesinin makul (60dB altı), motor titreşiminin düşük olduğu kontrol edilir. Sızdırmazlık testi için ya yüksek basınçlı su ile veya yağmurlu havayı bekleyerek alt drenaj kanalının doğru çalıştığı doğrulanır. Müşteriye teslim öncesi kumanda eşleştirilir, kullanım kılavuzu verilir, garanti belgesi (genelde 2 yıl) düzenlenir. Kavira Giyotin programının PDF teklif çıktısı aynı zamanda imalat fişi olarak kullanılabilir."),
        ],
        "faq": [
            ("Bir giyotin sistemi imalatı ne kadar sürer?", "Tek bir sistem (3000×3000mm) için ölçü alma + kesim + montaj + test toplam 1-2 iş günü sürer. Seri üretimde 3-5 sistem aynı atölyede paralel imal edilebilir."),
            ("İmalatta en sık yapılan hata nedir?", "Yan kasa profilinin yanlış uzunlukta kesilmesi (örn. H yerine L formülünün kullanılması). Bu Saray GYT-80'in 14515 hareketli ray profilinde tipik bir hatadır."),
            ("Sahada montaj öncesi neler hazırlanmalı?", "Balkon zemininin terazide olması, yan duvarlarda dübel için sağlam beton bulunması, elektrik prizinin 220V/16A çekebilecek yakınlıkta olması ve internet (uzaktan kumanda eşleştirme için bazı modellerde) gereklidir."),
        ],
    },
    {
        "slug": "isi-camli-giyotin",
        "title": "Isıcamlı Giyotin Cam Sistemi: Yapı, Avantaj, Maliyet",
        "desc": "Isıcamlı giyotin cam balkon sistemi nedir, 4+12+4 ısı camı yapısı, ısı ve ses yalıtımı, tek cam ile maliyet karşılaştırması ve uygun kullanım alanları.",
        "h1": "Isıcamlı Giyotin Cam Sistemi",
        "anahtarlar": ["ısıcamlı giyotin", "ısı camlı giyotin", "çift cam giyotin"],
        "bolumler": [
            ("Isıcamlı Giyotin Nedir?", "Isıcamlı (çift camlı) giyotin sistemi, her cam panelinde iki temperli cam tabakası arasında hava veya argon gazı boşluğu bulunan 4mm+12mm+4mm veya 4mm+16mm+4mm kombinasyonlu cam yapısı kullanan giyotin tipidir. Bu yapı tek cam (8mm) sistemlere göre %50-60 daha iyi ısı yalıtımı, %30-40 daha iyi ses yalıtımı sağlar. Türkiye'de Asistal G130T (Vertical Sliding Glass Balcony System with Thermal Glass), Tema T.24XX, Mavera TGI serisi ve Tümen Isı Bariyerli ürünleri ısıcamlı giyotin örnekleridir."),
            ("Isıcamlı Sistem Profil Yapısı", "Tek cam sistemlere göre ısıcamlı profillerin temel farkı kanat çerçevesinin daha geniş olmasıdır — ısıcam tabakası 24mm kalınlığındadır (tek cam 8mm). Örneğin Asistal G130T 11 kanat profili 30×38mm iç ölçüye sahiptir, ısıcam paneli içine sıkıca oturur. Mavera sisteminde aynı pencere için ısıcam (TGI serisi) veya tek cam (TCT serisi) profil seçimi yapılabilir, fiyat farkı yaklaşık %12-15'tir."),
            ("Isı Yalıtım Performansı (U-Değeri)", "Tek camlı giyotin sistemin U-değeri yaklaşık 5.7 W/m²K iken, 4+12+4 ısıcamlı sistemde 2.8 W/m²K seviyesine düşer. Low-E (düşük emisivite) kaplamalı ısıcamda bu değer 1.8 W/m²K'e kadar iner. Pratik anlamda: ısıcamlı sistem kışın iç ortamdan dışarıya ısı kaybını %50'den fazla azaltır, klimalı yazlarda da sıcaklığın içeriye girmesini engeller. Bu doğrudan kombi/klima enerji faturasını %15-25 düşürür."),
            ("Ses Yalıtım Performansı", "Tek camlı sistem 22-25 dB ses yalıtımı sunarken, 4+12+4 ısıcamlı sistemde 28-32 dB, asimetrik 6+12+4 kombinasyonunda 35 dB'ye kadar çıkar. Bu trafik gürültüsü olan caddeye bakan balkonlarda %50 algılanabilir ses azalması anlamına gelir. Restoran, kafe ve otel terasları gibi ticari mekanlarda müşteri konforu açısından ısıcamlı sistem büyük fark yaratır."),
            ("Maliyet Karşılaştırması", "2026 verileriyle 3000×3000mm bir pencerede tek cam giyotin (8mm temperli) toplam maliyet ortalama 38.000-45.000 TL iken, aynı boyut ısıcamlı sistemde 48.000-58.000 TL'dir. Fark %25-30 cama ek ödenir. Ancak yıllık enerji tasarrufu yaklaşık 2.500-4.000 TL olduğu için ısıcamlı sistem 3-4 yılda kendini amorti eder. Üst kat dairelerde, otel balkonlarında ve uzun süre kullanılan terasta ısıcamlı yatırım hep haklı çıkar."),
            ("Hangi Tedarikçi Hangi Sistem?", "Türkiye'de ısıcamlı giyotin sunan başlıca tedarikçiler: Asistal G130T (tam ısıcamlı premium sistem, motor şase çift duvarlı), Tema T.24XX (çift vasistaslı silinebilir ısıcam), Mavera TGI serisi (ısıcam) + TCT alternatifi (tek cam), Tümen GI-ART Isı Bariyerli (15 profil özel ısı bariyer serisi). Kavira Giyotin programı bu 4 tedarikçinin ısıcamlı sistemlerini kendi profil seti ve kg/m değerleriyle hesaplar — kullanıcı tedarikçi seçer, sistem otomatik doğru reçeteyi uygular."),
        ],
        "faq": [
            ("Isıcam panelinin garantisi ne kadar?", "Cam üreticisi 5 yıl 'cam içine yoğuşma olmama' garantisi verir. Doğru üretildiyse 15-20 yıl sorunsuz çalışır."),
            ("Argon gazlı ısıcam ekstradan ne kadar pahalı?", "Hava boşluklu ısıcama göre m² başına 200-300 TL daha pahalıdır, U-değeri 0.3-0.5 puan iyileşir."),
            ("Tek camdan ısıcama sonradan geçiş mümkün mü?", "Mevcut sistemin kanat profilleri 8mm cam için tasarlandıysa hayır — ısıcam tabakası daha kalın olduğu için profil değişimi gerekir. Yeni sistem alımı önerilir."),
        ],
    },
    {
        "slug": "silinebilir-giyotin",
        "title": "Silinebilir Giyotin Nedir? Klasik Sistem ile Farkları",
        "desc": "Silinebilir (temizlenebilir) giyotin cam sistemi nedir, klasik giyotin'den farkları, vasistas mekanizması, dış cam yüzeyinin içeriden temizlenmesi ve maliyet etkisi.",
        "h1": "Silinebilir Giyotin Sistemi",
        "anahtarlar": ["silinebilir giyotin", "temizlenebilir giyotin", "vasistas giyotin"],
        "bolumler": [
            ("Silinebilir Giyotin Kavramı", "Silinebilir (temizlenebilir, cleanable) giyotin cam sistemi, alt cam panelinin içeriye doğru açılmasını sağlayan vasistas mekanizmasıyla donatılmış giyotin tipidir. Bu mekanizma sayesinde balkonun dış yüzü içeriden silinerek temizlenebilir — bu özellik özellikle yüksek katlarda ve dışarıya çıkılması imkansız (cephe iskelesi gerektiren) projelerde kritiktir. Zahit Vetrina, Tema, Tümen GI-ART Temizlenebilir ve Asistal G130T silinebilir özellikli giyotin örnekleridir."),
            ("Klasik Giyotin'den Farkları", "Klasik giyotinde cam paneller sadece dikey hareket eder ve dış yüzü temizlemek için cephe iskelesi veya ip atletizmi gerekir. Silinebilir giyotinde ise alt panel ek bir mafsalla içeriye doğru 45-90° açılır, kullanıcı içeriden uzanarak cam dışını silebilir. Bunun için gereken ek profiller: tutamaklı baza (Zahit V.GY.206, Tümen G-2917), vasistas kasa (V.GY.204), orta vasistas alt kasa (V.GY.209) ve özel takozlar (GY-19/20/21/22/23). Mekanik aksesuarlarda vasistas makas (GY-26), vasistas kol (GY-25), ispanyolet kilit (GY-27) bulunur."),
            ("Maliyet Etkisi", "Silinebilir özellik klasik sisteme göre yaklaşık %12-18 maliyet artışı getirir. Ek profillerin maliyeti %4-6, ek mekanik aksesuarların maliyeti %8-12'dir. 3000×3000mm bir sistemde klasik versiyon ortalama 42.000 TL iken silinebilir Vetrina yaklaşık 48.000 TL maliyet çıkarır. Ancak yüksek katlarda dış temizlik maliyetinin yıllık 800-1500 TL olduğu düşünüldüğünde silinebilir sistem 5-6 yılda kendini amorti eder."),
            ("Vasistas Mekanizması Nasıl Çalışır?", "Alt panel kullanıcı tarafından içerideki kol (GY-25 vasistas kol) ile çevrilir. Kol ispanyolet kilidini (GY-27) ve sağ-sol kenarlardaki vasistas makasları (GY-26) hareket ettirir. Vasistas makasları üst kenarı mafsala bağlı tutarken alt kenarı içeriye doğru 45-90° açar. Cam paneli içeriye eğildiğinde kullanıcı sıkıştırılmış pencere tipi gibi içeriden uzanır ve dış cam yüzünü sünger veya bez ile temizler. Temizlik sonrası kol tekrar çevrilir, panel orijinal düz pozisyona kilitlenir."),
            ("Kimler Tercih Eder?", "Silinebilir giyotin özellikle şu durumlarda tercih edilir: 1) 4. kat ve üzeri konutlar (dışarıdan ulaşılamayan cephe), 2) Sahil kasabalarında deniz tuzu ve kumdan dolayı cam yüzeyi sık kirlenen evler, 3) Lokanta ve kafe terasları (vitrin temizliği günlük gerektiren mekanlar), 4) Otel odaları (housekeeping rutini için kolay temizlik), 5) Ofis pencereleri (hijyen önemli). Düşük katlı, dış cephesine kolay ulaşılan villalarda klasik sistem yeterlidir."),
            ("Hangi Tedarikçi Hangi Silinebilir Sistem?", "Türkiye'de silinebilir giyotin üreten ana firmalar: Zahit Alüminyum Vetrina (V.GY.2XX serisi, 15 profil, en kapsamlı sistem), Asistal G130T (ısıcamlı + silinebilir), Tema Çift Vasistaslı (T.2493 + T.2495 sabitleme aparatları), Tümen GI-ART Temizlenebilir (G-2917 tutamaklı çekme + GI-ART-A-11 push kol). Kavira Giyotin programı her tedarikçinin kendi vasistas reçetesini bilir — kullanıcı silinebilir sistemi seçtiğinde 13'e kadar ek aksesuar otomatik teklife eklenir."),
        ],
        "faq": [
            ("Silinebilir sistem ne sıklıkla cam temizliği gerektirir?", "Şehir merkezinde 2-3 ayda 1, sahilde 1 ayda 1, kafe terasta haftada 1 temizlik yapmak yeterlidir."),
            ("Vasistas mekanizması ne kadar dayanıklı?", "Kaliteli vasistas makas 50.000 açma-kapama döngüsü garanti eder, yani günde 1 kez açılırsa 130 yıl, haftada 1 kez ise 900+ yıl dayanır."),
            ("Silinebilir sistem rüzgarla zarar görür mü?", "Vasistas kol kapalı olduğunda sistem rüzgar yüküne klasik giyotin kadar dayanıklıdır. Açıkken (temizlik sırasında) kullanıcının panelin elinde tutması gerekir."),
        ],
    },
    {
        "slug": "giyotin-aksesuar-listesi",
        "title": "Giyotin Cam Aksesuar Listesi ve Fiyat Hesaplama",
        "desc": "Giyotin cam balkon sisteminde kullanılan tüm aksesuarların listesi: köşe takozu, rulman yatağı, boru başı, motor, kumanda, kayış, zincir, fitiller ve adet/metre fiyatlama.",
        "h1": "Giyotin Cam Aksesuar Listesi",
        "anahtarlar": ["giyotin aksesuar", "giyotin aksesuar listesi", "giyotin fitil"],
        "bolumler": [
            ("Aksesuarların 3 Kategorisi", "Giyotin cam sisteminde kullanılan aksesuarlar 3 ana fiyatlama kategorisinde değerlendirilir: 1) Adet fiyatlı PVC/metal aksesuarlar (köşe takozu, kapak, takoz, mekanik parça), 2) Metre fiyatlı fitiller ve sızdırmazlıklar (cam fitili, kıl fitil, EPDM kenet fitili), 3) Sistem başı sabit aksesuarlar (motor, kumanda, kayışlı set). Her tedarikçinin kendi aksesuar kodları olmasına rağmen fonksiyonları benzerdir."),
            ("Adet Fiyatlı Yapısal Aksesuarlar", "Köşe Takozu (örn. GY-01): kasa profilleri arasındaki birleştirme parçası, her köşeye 1 adet — sistem başı 4 adet (4 köşe). Rulman Yatağı: motor borusunun ucundaki bilyalı yatak, 1-2 adet. Boru Başı Kapağı: motor borusunun ucunu kapatan PVC parça, 2 adet. Merkezleme Takozu: hareketli panellerin yan kasada doğru hizada kalmasını sağlar, 6-8 adet. Vasistas Takozu (silinebilir sistemlerde): cam panelin içe açılmasını sağlayan mafsal noktası, 2 adet (sağ+sol). 2026 ortalama fiyatlar: köşe takozu 35-55 TL, rulman 25-35 TL, boru başı 30-40 TL, merkezleme takozu 10-15 TL."),
            ("Metre Fiyatlı Fitil ve Sızdırmazlıklar", "EPDM Cam Fitili: cam paneli profile bağlamak için profile yerleştirilen siyah kauçuk fitil, cam çevresi × cam adedi metre cinsinden hesaplanır — 2026'da 7-10 TL/m. Kıl Fitili (LS55520): hareketli kanat ile yan kasa arasında fırça benzeri sızdırmazlık, kanat yüksekliği × 12 adet (Saray standardı) — 4-6 TL/m. Flock Fitili (ZF-1): kanat profilinin oturduğu yere yerleştirilen kadife kumaş tabakası — 4-7 TL/m. EPDM Kenet Fitili (W55.511): kenet çekme profili çevresinde yer alan sızdırmazlık — 6-9 TL/m. Kapak Baskı Fitili (Z-94): kasa kapaklarının basıldığı yerde yer alan EPDM şerit — 5-7 TL/m."),
            ("Motor ve Kumanda Sistemleri", "Tüp Motor (120Nm-140Nm): standart 35mm çaplı tüp motor, dahili limit switch ile çalışır, 3.500-4.500 TL aralığında. Kayışlı Motor Set: triger dişli kayışı + kayış kasnağı + motor + kumanda dahil komple set, 4.000-5.500 TL. Kumanda: 433MHz, 1-15 kanal, tekli veya çoklu — 600-1.000 TL. Zincir Dişlisi (GY-11): paslanmaz çelik, motor borusu ucuna takılı, 130-160 TL. Zincir Yönlendirici (GY-13): zincirin yan kasada doğru yolda kalmasını sağlar, 55-75 TL."),
            ("Vasistas Mekanizması (Silinebilir Sistemlerde)", "Vasistas Makas (GY-26 / ASI-V 0501): silinebilir sistemin alt panelini içeriye doğru 45-90° açan paslanmaz çelik mafsal, sağ-sol 2 adet. 2026 ortalama 150-220 TL/adet. Vasistas Kol (GY-25): kullanıcının panel açma kapama için çevirdiği plastik+metal kol, 2 adet, 100-140 TL. İspanyolet Kilit (GY-27): kolun mekanik kilit görevi gören parçası, 2 adet, 100-150 TL. Zamak İspanyolet Karşılığı: ispanyoletin kilitlendiği karşı parça (kasa profiline gömülü), 40-60 TL."),
            ("Tedarikçi Spesifik Aksesuarlar", "Bazı aksesuarlar belirli tedarikçilere özgüdür: Asistal G130T'de EM-G130-TK PVC kapak takımı, G130T-A1 motor yan sacı, G130-A01 zincir kılavuz yüzüğü; Tümen GI-ART'ta GI-ART-A-11 push kol (manuel açma için), GI-ART-A-18 motor lazeri, GI-ART-A-14 altıgen kasnak; Tema'da TA.04.13.01.01 zincirli set ve TA.04.13.00.01 kayışlı set komple paketler. Kavira Giyotin programı tedarikçi seçildiğinde sadece o tedarikçinin gerçek aksesuar listesini ekler — yanlış ürün kodu teklif edilmez."),
        ],
        "faq": [
            ("Aksesuar maliyeti toplamın ne kadarını oluşturur?", "Ortalama %15-22'sini. Silinebilir sistemlerde vasistas mekanizması ek %5-7 maliyet ekler."),
            ("Aksesuar fitiller stoklanmalı mı yoksa proje bazlı mı alınmalı?", "EPDM cam fitili ve kıl fitili sürekli stoklanır (12 ay raf ömrü). Vasistas makas gibi spesifik mekanik aksesuarlar proje bazlı sipariş edilir."),
            ("Çin malı aksesuar kullanmak güvenli mi?", "Mekanik aksesuarlarda (vasistas makas, ispanyolet, motor) Avrupa veya Türk üretimi tercih edilmelidir. Çin mekanikleri 6-12 ay sonra arıza yapar. Fitiller ve plastik takozlarda Çin uygundur."),
        ],
    },
    {
        "slug": "giyotin-motor-secimi",
        "title": "Giyotin Cam Motor Seçimi: Kayışlı vs Zincirli Karşılaştırması",
        "desc": "Giyotin cam balkon için motor seçimi: kayışlı sistem ve zincirli sistem karşılaştırması, motor gücü hesaplama, sessizlik, dayanıklılık ve maliyet farkları.",
        "h1": "Giyotin Cam Motor Seçimi: Kayışlı vs Zincirli",
        "anahtarlar": ["giyotin motor", "giyotin motor seçimi", "kayışlı zincirli giyotin"],
        "bolumler": [
            ("Motor Tipinin Önemi", "Giyotin cam sistemde motor + hareket aktarım mekanizması toplam maliyetin %15-20'sini oluşturur ve sistemin günlük kullanım deneyimini doğrudan belirler. Hatalı motor seçimi kısa sürede arıza, gürültü, hareket düzensizliği ve kullanıcı şikayetlerine yol açar. İki ana hareket mekanizması var: zincirli ve kayışlı. Hangisinin tercih edileceği balkon ölçüsü, cam ağırlığı, kullanım sıklığı ve atölyenin standart kullandığı tedarikçi sistemine göre belirlenir."),
            ("Zincirli Sistem Çalışma Prensibi", "Zincirli sistemde paslanmaz çelik zincir motorun ucuna takılı dişliyle dönüş alır ve sağ-sol kenardaki yan kasalardan aşağıya iner, alt ucu hareketli cam panelin kenarına bağlanır. Zincirin tersi yöne dönüşü sırasında cam paneli yukarı kaldırılır. Sistem çok düşük sürtünme ile çalışır, bu nedenle nispeten sessizdir (45-55 dB) ve yüksek cam ağırlıklarını (60 kg/m²'ye kadar) destekler. Saray GYT-80 ve Mavera MVR zincirli sistemde güçlüdür."),
            ("Kayışlı Sistem Çalışma Prensibi", "Kayışlı sistemde paslanmaz çelik tel takviyeli triger dişli kayış motor kasnağı tarafından çevrilir ve cam panele bağlanır. Zincire göre daha hafif olduğu için motor yükü %15-20 daha düşüktür. Kayış tek parça olduğu için zincir baklalarının arasındaki sürtünme yoktur, hareket akıcıdır. Ancak kayışın uzun ömürlü olması için kaliteli üretim (Mitsuboshi, Continental gibi) şart, ucuz kayışlar 2-3 yıl içinde aşınır. Tümen GI-ART ve Tema kayışlı opsiyonda güçlüdür."),
            ("Karşılaştırma Tablosu", "Sessizlik: kayışlı 40-50 dB / zincirli 45-55 dB. Cam ağırlık kapasitesi: kayışlı 40 kg/m² / zincirli 60 kg/m². Maliyet (motor set olarak): kayışlı 4.000-4.500 TL / zincirli 4.500-5.500 TL. Bakım sıklığı: kayışlı 2 yılda kayış kontrolü / zincirli 5 yılda zincir yağlama. Kullanım ömrü: kayışlı 8-12 yıl / zincirli 15-20 yıl. Sıcaklık toleransı: kayışlı -10°C ile +60°C / zincirli -25°C ile +80°C. Tropikal iklim, sahil veya soğuk bölgelerde zincirli, normal şehir konutlarında kayışlı önerilir."),
            ("Motor Gücü Hesaplama", "Tüp motor gücü Newton-metre (Nm) cinsinden ifade edilir. Standart 120Nm motor 3000×3000mm tek camlı sistemi rahat kaldırır. 130Nm motor aynı boyutu ısıcamlı (ek %15 cam ağırlığı) destekler. 140Nm motor 3500×3500mm sistemleri kaldırır. Daha büyük sistemlerde (4000mm+ genişlik) çift motor veya 170Nm motor seçimi gerekir. Cam ağırlığı pratik hesabı: ısıcam panel = 24 kg/m², tek cam panel = 16 kg/m². 3000×1000mm cam paneli ısıcam için 72 kg, tek cam için 48 kg. Motor 3 paneli + yan kasaları taşıyacağı için emniyet payı eklenir."),
            ("Tedarikçi Bazlı Motor Önerileri", "Katar Klasik Giyotin: kayışlı set + Somfy 120Nm motor, 433MHz kumanda. Saray GYT-80: zincirli sistem, SC-941 özel zincir × 2.5m × 2 adet, SC-930 dişli + SC-937 kılavuz plastiği. Zahit Vetrina: kayışlı veya zincirli alternatif, GY-14 zincir 2.5m veya GY-17 kayış 2.5m. Asistal G130T: G100-A1 120'lik tüp motor, G100-A3 çoklu kumanda. Tema: TA.04.13.01.01 zincirli set veya TA.04.13.00.01 kayışlı set, 120-140Nm Somfy motor. Tümen GI-ART: kayışlı veya zincirli, GI-ART-A-13 boru başı milli + GI-ART-A-14 altıgen kasnak (kayışlı) veya GI-ART-A-21 altıgen dişli (zincirli)."),
        ],
        "faq": [
            ("Motor arızalandığında değişim ne kadar sürer?", "Yan kasa profili sökülmeden 30-60 dakika içinde değişir. Aynı marka/güçte motor stokta varsa aynı gün değiştirilir."),
            ("Smart home (Google Home, Alexa) ile çalışan giyotin motoru var mı?", "Somfy IO ve Becker EnOcean motorlar uyumludur. Bu modeller standart RF motora göre %30-40 daha pahalıdır."),
            ("Motor garantisi ne kadar?", "Avrupa menşeli (Somfy, Becker, Cherubini): 5 yıl. Türk üretimi (Mervas, MTM): 2 yıl. Çin üretimi: 1 yıl, önerilmez."),
        ],
    },
]


# ─────────────────────────────────────────────────────────────
# HTML TEMPLATE — sade, hızlı yüklenen, SEO-optimized
# ─────────────────────────────────────────────────────────────
STYLE = """*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#0B1220;--card:#0F172A;--border:rgba(148,163,184,.18);--text:#E2E8F0;--muted:#94A3B8;--accent:#5B7C99;--accent2:#0EA5E9}
html{scroll-behavior:smooth;-webkit-text-size-adjust:100%}
body{font-family:Inter,system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;background:var(--bg);color:var(--text);line-height:1.65;min-height:100vh}
.container{max-width:920px;margin:0 auto;padding:0 24px}
header{position:sticky;top:0;background:rgba(11,18,32,.92);backdrop-filter:blur(10px);border-bottom:1px solid var(--border);z-index:10}
.nav{display:flex;align-items:center;justify-content:space-between;height:64px}
.logo{font-weight:800;font-size:18px;color:var(--text);text-decoration:none;letter-spacing:-.3px}
.logo span{color:var(--accent2)}
nav ul{display:flex;list-style:none;gap:24px}
nav a{color:var(--muted);text-decoration:none;font-size:14px;transition:color .15s}
nav a:hover{color:var(--text)}
.bc{padding:18px 0;font-size:13px;color:var(--muted)}
.bc a{color:var(--accent2);text-decoration:none}
.bc a:hover{text-decoration:underline}
h1{font-size:36px;line-height:1.2;margin:24px 0 16px;letter-spacing:-.6px;font-weight:800}
.lead{font-size:18px;color:var(--muted);margin-bottom:36px;line-height:1.65}
h2{font-size:24px;margin:48px 0 16px;letter-spacing:-.3px;font-weight:700;border-left:3px solid var(--accent2);padding-left:14px}
h3{font-size:18px;margin:24px 0 10px;color:var(--text);font-weight:600}
p{margin-bottom:14px}
ul.list{margin:12px 0 18px 24px}
ul.list li{margin:6px 0;color:var(--muted)}
table{width:100%;border-collapse:collapse;margin:18px 0;background:var(--card);border:1px solid var(--border);border-radius:8px;overflow:hidden}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid var(--border);font-size:14px}
th{background:rgba(255,255,255,.03);color:var(--text);font-weight:600}
td{color:var(--muted)}
td:first-child{color:var(--text);font-weight:500;font-family:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace}
.faq{margin:32px 0}
.faq details{background:var(--card);border:1px solid var(--border);border-radius:10px;padding:0;margin-bottom:10px}
.faq summary{padding:16px 20px;cursor:pointer;font-weight:600;color:var(--text);outline:none;list-style:none}
.faq summary::-webkit-details-marker{display:none}
.faq summary::after{content:'+';float:right;color:var(--accent2);font-size:20px;font-weight:300}
.faq details[open] summary::after{content:'−'}
.faq details p{padding:0 20px 18px;color:var(--muted);border-top:1px solid var(--border);padding-top:14px}
.cta{background:linear-gradient(135deg,#0EA5E9,#0369A1);border-radius:14px;padding:32px;text-align:center;margin:48px 0}
.cta h3{color:#fff;font-size:22px;margin-bottom:10px}
.cta p{color:rgba(255,255,255,.85);margin-bottom:18px}
.cta a{display:inline-block;background:#fff;color:#0369A1;padding:12px 28px;border-radius:10px;text-decoration:none;font-weight:700;font-size:15px;transition:transform .15s}
.cta a:hover{transform:translateY(-2px)}
.related{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px;margin:32px 0}
.related a{display:block;background:var(--card);border:1px solid var(--border);border-radius:10px;padding:18px;color:var(--text);text-decoration:none;transition:border-color .15s,transform .15s}
.related a:hover{border-color:var(--accent2);transform:translateY(-2px)}
.related .rt{font-weight:600;margin-bottom:6px;font-size:15px}
.related .rd{color:var(--muted);font-size:13px}
footer{border-top:1px solid var(--border);padding:32px 0;margin-top:64px;color:var(--muted);font-size:13px;text-align:center}
footer a{color:var(--accent2);text-decoration:none;margin:0 8px}
@media(max-width:640px){h1{font-size:28px}h2{font-size:20px}.container{padding:0 16px}nav ul{display:none}}"""


def page_html(*, title, desc, slug, h1, breadcrumb, content_html, faq_pairs, related_links):
    canonical = f"{BASE_URL}/{slug}"
    faq_schema = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {
                "@type": "Question",
                "name": q,
                "acceptedAnswer": {"@type": "Answer", "text": a},
            }
            for q, a in faq_pairs
        ],
    }
    breadcrumb_schema = {
        "@context": "https://schema.org",
        "@type": "BreadcrumbList",
        "itemListElement": [
            {"@type": "ListItem", "position": i + 1, "name": n, "item": u}
            for i, (n, u) in enumerate(breadcrumb)
        ],
    }
    article_schema = {
        "@context": "https://schema.org",
        "@type": "Article",
        "headline": title,
        "description": desc,
        "url": canonical,
        "datePublished": "2026-06-13",
        "dateModified": "2026-06-13",
        "author": {"@type": "Organization", "name": "Kavira Software", "url": BASE_URL},
        "publisher": {"@type": "Organization", "name": "Kavira Software", "url": BASE_URL},
        "inLanguage": "tr",
        "mainEntityOfPage": {"@type": "WebPage", "@id": canonical},
    }
    schemas = json.dumps([article_schema, faq_schema, breadcrumb_schema], ensure_ascii=False, indent=0)

    bc_html = " &rsaquo; ".join(
        f'<a href="{u}">{n}</a>' if u else f"<span>{n}</span>" for n, u in breadcrumb
    )
    faq_html = "".join(
        f"<details><summary>{q}</summary><p>{a}</p></details>" for q, a in faq_pairs
    )
    related_html = "".join(
        f'<a href="{u}"><div class="rt">{t}</div><div class="rd">{d}</div></a>'
        for u, t, d in related_links
    )

    return f"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>{title}</title>
<meta name="description" content="{desc}">
<meta name="robots" content="index,follow">
<link rel="canonical" href="{canonical}">
<meta property="og:type" content="article">
<meta property="og:url" content="{canonical}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:image" content="{BASE_URL}/og-image.png">
<meta property="og:locale" content="tr_TR">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{desc}">
<meta name="twitter:image" content="{BASE_URL}/og-image.png">
<script type="application/ld+json">{schemas}</script>
<link rel="icon" type="image/png" href="/favicon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>{STYLE}</style>
</head>
<body>
<header><div class="container nav">
<a href="/" class="logo">Kavira<span>.</span></a>
<nav><ul>
<li><a href="/">Anasayfa</a></li>
<li><a href="/rehber">Rehber</a></li>
<li><a href="/app/">Programa Git</a></li>
</ul></nav>
</div></header>
<main class="container">
<div class="bc">{bc_html}</div>
<h1>{h1}</h1>
<p class="lead">{desc}</p>
{content_html}
<div class="cta">
<h3>Ücretsiz hesaplamaya hemen başlayın</h3>
<p>Kavira Giyotin programı 8 tedarikçinin profil seti ve aksesuar reçetesiyle tek tıkla maliyet, kesim planı ve PDF teklif çıkarır. Erken erişim — tamamen ücretsiz.</p>
<a href="/app/">Programı Aç</a>
</div>
<h2>İlgili Sayfalar</h2>
<div class="related">{related_html}</div>
<div class="faq">
<h2>Sıkça Sorulan Sorular</h2>
{faq_html}
</div>
</main>
<footer><div class="container">
© 2026 Kavira Software — Giyotin Cam Hesaplama Programı
<br><br>
<a href="/">Anasayfa</a> · <a href="/rehber">Rehber</a> · <a href="/terms">Kullanım Koşulları</a> · <a href="/privacy">Gizlilik</a>
</div></footer>
</body>
</html>"""


def vendor_content(v):
    profil_rows = "".join(
        f"<tr><td>{kod}</td><td>{isim}</td><td>{kg} kg/m</td></tr>"
        for kod, isim, kg in v["ornek_profiller"]
    )
    return dedent(f"""
        <h2>{v['name']} — {v['system']}</h2>
        <p>{v['intro']}</p>
        <h2>Profil Setine Genel Bakış</h2>
        <p>{v['name']} {v['system']} {v['profil_sayisi']} farklı profil kodu kullanır. Profil önek kodu <strong>{v['code_prefix']}</strong> ile başlar. Aşağıda sistem profillerinin örnek bir alt kümesi ve kg/m ağırlıkları yer alır:</p>
        <table><thead><tr><th>Kod</th><th>Profil Adı</th><th>Ağırlık</th></tr></thead><tbody>{profil_rows}</tbody></table>
        <h2>Cam Ölçü Formülleri</h2>
        <p>{v['name']} sisteminde cam paneli ölçüleri aşağıdaki formüllerle hesaplanır:</p>
        <ul class="list">
        <li><strong>Cam Genişliği:</strong> {v['cam_en_formul']}</li>
        <li><strong>Cam Yüksekliği:</strong> {v['cam_boy_formul']} (her cam paneli için)</li>
        <li><strong>Panel Sayısı:</strong> {v['panel_count']} adet (standart konfigürasyon)</li>
        </ul>
        <h2>Sistemin Özellikleri</h2>
        <p>{v['ozellik']}</p>
        <h2>Standart Aksesuar Reçetesi</h2>
        <p>{v['aksesuar']}</p>
        <h2>Bu Tedarikçiyle Nasıl Hesap Yapılır?</h2>
        <p>Kavira Giyotin programında {v['name']} sistemiyle hesap yapmak için: 1) Tedarikçi seçim ekranından "{v['name']}" seçin, 2) "{v['system']}" alt sistemini doğrulayın, 3) Pencere genişliği, yüksekliği ve sistem adedi girin, 4) Hesapla butonuna basın. Program yukarıdaki profil setini ve aksesuar reçetesini bire bir uygular, bin-packing kesim planı çıkarır, müşteriye gönderilebilir PDF teklif üretir.</p>
        <p>Birim fiyatlar (alüminyum kg/TL, cam m²/TL, motor TL, aksesuar TL) Ayarlar ekranından girilir ve atölyenize özgü olarak saklanır. Aynı tedarikçi için bir kez fiyatları girdikten sonra her yeni hesap birkaç saniye sürer.</p>
    """).strip()


def topic_content(t):
    sections = ""
    for h2_title, body in t["bolumler"]:
        sections += f"<h2>{h2_title}</h2><p>{body}</p>"
    return sections


# ─────────────────────────────────────────────────────────────
# Sayfa üretimi
# ─────────────────────────────────────────────────────────────
def all_vendors_related(current_slug):
    return [
        (f"/tedarikci/{v['slug']}", f"{v['name']} {v['system']}", f"{v['profil_sayisi']} profil · {v['code_prefix']} serisi")
        for v in VENDORS if v["slug"] != current_slug
    ]


def all_topics_related(current_slug):
    return [
        (f"/{t['slug']}", t["h1"], t["desc"][:90] + "...")
        for t in TOPICS if t["slug"] != current_slug
    ]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "tedarikci").mkdir(exist_ok=True)
    new_urls = []

    print(f"→ Output: {OUT}")

    # 8 VENDOR
    for v in VENDORS:
        title = f"{v['name']} {v['system']} Hesaplama Programı | Kavira Giyotin"
        desc = (
            f"{v['name']} {v['system']} için ücretsiz fiyat, kesim planı ve maliyet "
            f"hesaplama programı. {v['profil_sayisi']} profil kodu, gerçek kg/m ağırlıkları "
            f"ve aksesuar reçetesi kataloga bire bir uyumlu."
        )
        slug = f"tedarikci/{v['slug']}"
        breadcrumb = [
            ("Anasayfa", "/"),
            ("Tedarikçiler", None),
            (f"{v['name']} {v['system']}", None),
        ]
        related = [(f"/tedarikci/{ov['slug']}", f"{ov['name']} {ov['system']}", f"{ov['profil_sayisi']} profil · {ov['code_prefix']} serisi") for ov in VENDORS if ov['slug'] != v['slug']][:6]
        faq = [
            (f"{v['name']} {v['system']} kaç panelli üretilir?", f"Standart konfigürasyon {v['panel_count']} cam panellidir. Daha küçük veya büyük varyantlar atölyenin tercihine göre üretilebilir."),
            (f"{v['name']} sistemi ısıcamlı çalışır mı?", "Tedarikçinin sistem alt-kategorisi ısıcam destekliyorsa evet — sistem detayı için yukarıdaki özelliklere bakın. Kavira Giyotin programı doğru cam tipini otomatik uygular."),
            ("Bu tedarikçinin profillerini Kavira'da nasıl kullanırım?", f"Program açıldığında 'Tedarikçi Seç' butonuna tıklayın, '{v['name']}' seçeneğini bulun. Sistem profilleri ve aksesuar reçetesi otomatik yüklenir."),
        ]
        html = page_html(
            title=title, desc=desc, slug=slug, h1=f"{v['name']} {v['system']} Hesaplama Programı",
            breadcrumb=breadcrumb, content_html=vendor_content(v),
            faq_pairs=faq, related_links=related,
        )
        out_path = OUT / "tedarikci" / f"{v['slug']}.html"
        out_path.write_text(html, encoding="utf-8")
        new_urls.append(f"{BASE_URL}/{slug}")
        print(f"  ✓ {slug}")

    # 8 TOPIC
    for t in TOPICS:
        title = f"{t['title']} | Kavira Giyotin"
        desc = t["desc"]
        slug = t["slug"]
        breadcrumb = [("Anasayfa", "/"), ("Rehber", "/rehber"), (t["h1"], None)]
        # related: 2 vendor + 4 topic
        related = [
            (f"/tedarikci/{VENDORS[0]['slug']}", f"{VENDORS[0]['name']}", f"{VENDORS[0]['profil_sayisi']} profil"),
            (f"/tedarikci/{VENDORS[3]['slug']}", f"{VENDORS[3]['name']} {VENDORS[3]['system']}", f"{VENDORS[3]['profil_sayisi']} profil"),
        ] + [(f"/{ot['slug']}", ot["h1"], ot["desc"][:90] + "...") for ot in TOPICS if ot["slug"] != t["slug"]][:4]
        html = page_html(
            title=title, desc=desc, slug=slug, h1=t["h1"],
            breadcrumb=breadcrumb, content_html=topic_content(t),
            faq_pairs=t["faq"], related_links=related,
        )
        out_path = OUT / f"{slug}.html"
        out_path.write_text(html, encoding="utf-8")
        new_urls.append(f"{BASE_URL}/{slug}")
        print(f"  ✓ {slug}")

    # SITEMAP'i de güncelle
    sitemap_entries = """  <url>
    <loc>https://kaviragiyotin.online/</loc>
    <lastmod>2026-06-13</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://kaviragiyotin.online/musteri</loc>
    <lastmod>2026-06-13</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.9</priority>
  </url>
  <url>
    <loc>https://kaviragiyotin.online/rehber</loc>
    <lastmod>2026-06-13</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
"""
    for v in VENDORS:
        sitemap_entries += f"""  <url>
    <loc>https://kaviragiyotin.online/tedarikci/{v['slug']}</loc>
    <lastmod>2026-06-13</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.85</priority>
  </url>
"""
    for t in TOPICS:
        sitemap_entries += f"""  <url>
    <loc>https://kaviragiyotin.online/{t['slug']}</loc>
    <lastmod>2026-06-13</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.85</priority>
  </url>
"""
    sitemap_entries += """  <url>
    <loc>https://kaviragiyotin.online/terms</loc>
    <lastmod>2026-06-06</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.4</priority>
  </url>
  <url>
    <loc>https://kaviragiyotin.online/privacy</loc>
    <lastmod>2026-06-06</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.4</priority>
  </url>
  <url>
    <loc>https://kaviragiyotin.online/cookies</loc>
    <lastmod>2026-06-06</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.3</priority>
  </url>
  <url>
    <loc>https://kaviragiyotin.online/accessibility</loc>
    <lastmod>2026-06-06</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.3</priority>
  </url>
"""
    sitemap_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
{sitemap_entries}</urlset>
"""
    (OUT / "sitemap.xml").write_text(sitemap_xml, encoding="utf-8")
    print(f"  ✓ sitemap.xml ({3 + len(VENDORS) + len(TOPICS) + 4} URL)")

    print(f"\n✅ Toplam {len(new_urls)} yeni sayfa üretildi.")
    return new_urls


if __name__ == "__main__":
    urls = main()
    for u in urls:
        print(f"  {u}")
