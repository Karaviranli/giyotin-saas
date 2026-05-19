import os
from datetime import datetime
from typing import Dict, List
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
        self.cell(0, 10, f"{self.company_name.upper()} - KESİM PLANI RAPORU", fill=True, align="C", new_x="LMARGIN", new_y="NEXT")
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
        pdf.cell(0, 6, cls._ascii(f"PROJE: {record['project_name']}"), align="C", new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        # Kapsamlı makine ayarları ve maliyet/fire özeti
        pdf.set_font("helvetica", "B", 10)
        pdf.set_fill_color(230, 230, 230)
        pdf.cell(0, 7, cls._ascii("SİSTEM BİLGİLERİ VE ÖZET"), fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        pdf.set_font("helvetica", "", 9)
        pdf.cell(50, 6, cls._ascii(f"Sistem Türü: {record['system_type']}"))
        pdf.cell(50, 6, cls._ascii(f"Ölçüler: {record['width']} x {record['height']} mm"))
        pdf.cell(50, 6, cls._ascii(f"Adet: {record['quantity']}"))
        pdf.ln(8)

        # Profil Kesim Listesi (Optimizasyon Çıktıları)
        pdf.set_font("helvetica", "B", 10)
        pdf.set_fill_color(230, 230, 230)
        pdf.cell(0, 7, cls._ascii("PROFİL KESİM LİSTESİ"), fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        pdf.set_font("helvetica", "", 8)
        profiller = record.get('cut_optimization', {}).get('profiller', [])
        
        for p in profiller:
            kod = cls._ascii(p.get("kod", ""))
            isim = cls._ascii(p.get("isim", ""))
            olcu = p.get("olcu", 0)
            adet = p.get("adet", 0)
            pdf.cell(0, 5, f"- KOD: {kod:<10} | {isim:<30} | {olcu} mm  x  {adet} Adet", new_x="LMARGIN", new_y="NEXT")

        pdf.ln(6)
        pdf.set_font("helvetica", "I", 8)
        pdf.set_text_color(110, 110, 110)
        pdf.multi_cell(0, 4, cls._ascii("Not: Bu rapor Kavira SaaS altyapısı tarafından üretilmiştir."))

        return bytes(pdf.output())