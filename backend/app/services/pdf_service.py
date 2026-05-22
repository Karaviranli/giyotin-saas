import os
import io
from datetime import datetime
from fpdf import FPDF

# Görsellerin bulunacağı klasör (Docker'da veya sunucuda bu klasörün yolunu ayarlayacağız)
IMAGES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates", "images")

class KesimPDF(FPDF):
    def __init__(self, company_name: str):
        super().__init__(orientation='P', unit='mm', format='A4')
        self.company_name = company_name
        self.set_auto_page_break(auto=True, margin=15)
        self.alias_nb_pages()

    def header(self):
        self.set_font("helvetica", "B", 14)
        self.set_fill_color(35, 35, 35)
        self.set_text_color(255, 255, 255)
        # Şirketin adına özel dinamik başlık
        self.cell(0, 10, f"{self.company_name.upper()} - KESIM PLANI RAPORU", fill=True, align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_text_color(0, 0, 0)
        self.ln(4)

    def footer(self):
        self.set_y(-12)
        self.set_font("helvetica", "I", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f"{datetime.now().strftime('%d.%m.%Y %H:%M')}  -  Sayfa {self.page_no()}/{{nb}}", align="C")
        self.set_text_color(0, 0, 0)

class PdfService:
    @staticmethod
    def _ascii(s: str) -> str:
        """Türkçe karakterleri ASCII'ye çevirir (helvetica fontu için)."""
        return (str(s).replace('ı', 'i').replace('İ', 'I').replace('ş', 's').replace('Ş', 'S')
                .replace('ğ', 'g').replace('Ğ', 'G').replace('ü', 'u').replace('Ü', 'U')
                .replace('ö', 'o').replace('Ö', 'O').replace('ç', 'c').replace('Ç', 'C'))

    @classmethod
    def generate_giyotin_pdf(cls, company_name: str, record: dict) -> bytes:
        """
        Veritabanından çekilen Giyotin hesaplama verisini alıp PDF byte array'ine çevirir.
        """
        pdf = KesimPDF(company_name=cls._ascii(company_name))
        pdf.add_page()

        # Proje Başlığı ve Özet
        pdf.set_font("helvetica", "B", 11)
        pdf.set_fill_color(225, 177, 44)
        pdf.cell(0, 10, cls._ascii(f"PROJE: {record['project_name']}"), fill=True, align="C", new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        pdf.set_font("helvetica", "B", 10)
        pdf.set_fill_color(230, 230, 230)
        pdf.cell(0, 7, cls._ascii("SISTEM BILGILERI VE OZET"), fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        pdf.set_font("helvetica", "", 9)
        if record.get('system_type') == "BİRLEŞİK KESİM":
            pdf.cell(60, 6, cls._ascii("Sistem Turu: Toplu Optimizasyon"))
            pdf.cell(60, 6, cls._ascii("Olculer: Karisik (Birlestirilmis)"))
            pdf.cell(50, 6, cls._ascii("Is Sayisi: Belirtilmedi"))
        else:
            pdf.cell(60, 6, cls._ascii(f"Sistem Turu: {record['system_type']}"))
            pdf.cell(60, 6, cls._ascii(f"Olculer: {record['width']} x {record['height']} mm"))
            pdf.cell(50, 6, cls._ascii(f"Adet: {record['quantity']}"))
        pdf.ln(8)

        # Kesim Planı (Kod Bazlı)
        kodlar = record.get('cut_optimization', {}).get('kodlar', {})
        for kod, rapor in kodlar.items():
            # Kod Başlığı
            pdf.set_font("helvetica", "B", 10)
            pdf.set_fill_color(60, 60, 60)
            pdf.set_text_color(255, 255, 255)
            pdf.cell(40, 8, cls._ascii(f"KOD: {kod}"), fill=True, align="C")
            
            pdf.set_text_color(0, 0, 0)
            pdf.set_font("helvetica", "", 8)
            pdf.set_fill_color(245, 245, 245)
            pdf.cell(0, 8, cls._ascii(f"  {rapor['stok_adedi']} Profil | Toplam Fire: {rapor['fire_mm']} mm"), fill=True, new_x="LMARGIN", new_y="NEXT")
            pdf.ln(1)

            # Tablo Header
            pdf.set_font("helvetica", "B", 8)
            pdf.set_fill_color(230, 230, 230)
            pdf.cell(15, 6, "#", border=1, fill=True, align="C")
            pdf.cell(145, 6, cls._ascii("Kesim Detayi (mm)"), border=1, fill=True)
            pdf.cell(30, 6, "Fire", border=1, fill=True, align="C", new_x="LMARGIN", new_y="NEXT")

            colors = [
                (52, 152, 219), (231, 76, 60), (155, 89, 182),
                (26, 188, 156), (241, 196, 15), (230, 126, 34), (52, 73, 94)
            ]

            # Satırlar
            for idx, b in enumerate(rapor['bins']):
                detay_parts = []
                for p in b['pieces']:
                    length_str = f"{int(p['length'])}"
                    if p.get('project_name'):
                        proj = cls._ascii(p['project_name'])
                        if len(proj) > 10: proj = proj[:8] + ".."
                        length_str += f" ({proj})"
                    detay_parts.append(length_str)
                
                detay = " + ".join(detay_parts)
                
                # Eğer metin hücreye sığmayacak kadar uzunsa fontu dinamik küçült
                pdf.set_font("helvetica", "", 8)
                if pdf.get_string_width(detay) > 143:
                    pdf.set_font("helvetica", "", 6)
                if pdf.get_string_width(detay) > 143:
                    pdf.set_font("helvetica", "", 5)
                
                # 1. Satır: Metinler (Alt çizgisi açık bırakıldı)
                pdf.cell(15, 6, str(idx+1), border="LTR", align="C")
                pdf.cell(145, 6, detay, border="LTR")
                
                # Fire rengi (yeşil < 50, sarı < 300)
                waste = b['waste']
                if waste < 50: pdf.set_text_color(46, 113, 27)
                elif waste < 300: pdf.set_text_color(150, 90, 0)
                else: pdf.set_text_color(160, 30, 30)
                
                pdf.cell(30, 6, f"{int(waste)} mm", border="LTR", align="C", new_x="LMARGIN", new_y="NEXT")
                pdf.set_text_color(0, 0, 0)

                # 2. Satır: Görsel Barlar (Üst çizgisi açık bırakıldı)
                pdf.cell(15, 6, "", border="LBR")
                
                # Barın çizileceği alanın X ve Y koordinatlarını al (145mm'lik orta hücre)
                bar_start_x = pdf.get_x()
                bar_start_y = pdf.get_y()
                
                pdf.cell(145, 6, "", border="LBR")
                pdf.cell(30, 6, "", border="LBR", new_x="LMARGIN", new_y="NEXT")
                
                next_row_x = pdf.get_x()
                next_row_y = pdf.get_y()
                
                # Çubuk hesaplamaları
                stock_w = sum(p['length'] for p in b['pieces']) + waste
                if stock_w == 0: stock_w = 1
                max_bar_width = 143 # Sağ ve soldan 1'er mm boşluk (padding)
                
                current_x = bar_start_x + 1
                y_pos = bar_start_y + 1
                bar_h = 4
                
                # Gri arkaplan (Tüm boy, geriye kalan fire alanını belli eder)
                pdf.set_fill_color(220, 220, 220)
                pdf.rect(current_x, y_pos, max_bar_width, bar_h, style='F')
                
                # Kesilen parçaları renkli olarak üstüne çiz
                for i, p in enumerate(b['pieces']):
                    w = (p['length'] / stock_w) * max_bar_width
                    color = colors[i % len(colors)]
                    pdf.set_fill_color(*color)
                    pdf.rect(current_x, y_pos, w, bar_h, style='F')
                    
                    # Eğer parça çubuğu yazının sığacağı kadar genişse, uzunluğunu içine yaz
                    text_to_print = f"{int(p['length'])}"
                    if w > 25 and p.get('project_name'):
                        proj = cls._ascii(p['project_name'])
                        if len(proj) > 8: proj = proj[:6] + ".."
                        text_to_print += f" ({proj})"
                        
                    if w > 8:
                        pdf.set_text_color(255, 255, 255)
                        pdf.set_font("helvetica", "B", 5 if len(text_to_print) > 5 else 6)
                        pdf.set_xy(current_x, y_pos)
                        pdf.cell(w, bar_h, text_to_print, align="C")
                        
                    current_x += w
                    
                # Ayarları sıfırla ve imleci bir sonraki satıra taşı
                pdf.set_text_color(0, 0, 0)
                pdf.set_font("helvetica", "", 8)
                pdf.set_xy(next_row_x, next_row_y)
                pdf.ln(1) # Satırlar arası minimal boşluk
                
            pdf.ln(3)

        pdf.ln(6)
        pdf.set_font("helvetica", "I", 8)
        pdf.set_text_color(110, 110, 110)
        pdf.multi_cell(0, 4, cls._ascii("Not: Bu rapor Kavira SaaS altyapısı tarafından üretilmiştir."))

        # Çıktıyı string veya byte array olarak bellekte (dest='S') tutmaya zorluyoruz.
        out = pdf.output(dest='S')
        if isinstance(out, str):
            return out.encode('latin-1')
        return bytes(out)