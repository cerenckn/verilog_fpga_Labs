# FPGA RAM Tabanlı Nesne Sayıcı ve Günlükçü (Object Counter Logger)

Bu proje, Verilog HDL kullanılarak geliştirilmiş, endüstriyel üretim bantlarındaki nesne sayım ve veri kayıt mantığını simüle eden bir donanım mimarisidir. **MZ80 Kızılötesi Proximity Sensöründen** gelen verileri gerçek zamanlı olarak sayar, kullanıcının komutuyla (kaydet butonu) verileri dahili **Tek Portlu RAM (Single-Port RAM)** bloğuna yazar ve kaydedilen geçmiş veriyi onboard LED'ler üzerinde gösterir.

## ⚙️ Donanım Tasarım Özellikleri

- **Metastabilite Engelleme:** Fiziksel sensör ve buton sinyalleri (asenkron girişler), FPGA saat domainine taşınırken 2-aşamalı register hatları (D-FlipFlop) üzerinden geçirilerek kararlı hale getirilmiştir.
- **Hassas Kenar Algılama:** Girişlerin dalgalanmasını önlemek ve kararlı sayım yapmak amacıyla sinyallerin sadece **düşen kenarları (falling edge)** izlenir.
- **Dinamik Adres Çoklayıcı (Address Mux):** Sistem, tek bir RAM portunu verimli kullanmak adına; yazma anında (`btn_edge`) aktif boş adrese odaklanırken, okuma anında otomatik olarak bir önceki kayıtlı adrese yönlenir.
- **Aktif-Düşük (Active-Low) Donanım Uyumu:** Tasarım, Gowin FPGA geliştirme kartlarındaki gömülü buton ve LED altyapısına tam uyumlu çalışacak şekilde konfigüre edilmiştir.

---

## 🏗 Sistem Blok Mimarisi ve Veri Akışı

Sistem içerisindeki sinyal akışı ve modüller arası hiyerarşi aşağıdaki şemada modellenmiştir:

```mermaid
graph LR
    subgraph Girişler [Asenkron Giriş Birimleri]
        MZ80([MZ80 Sensör Girişi])
        BTN([Kaydet Butonu])
    end

    subgraph TopModul [top.v - Ana Kontrolcü Mimarisi]
        direction TB
        
        subgraph Sync [Senkronizasyon & Kenar Algılama]
            MZ_Edge{Düşen Kenar?} 
            BTN_Edge{Düşen Kenar?}
        end
        
        subgraph Logic [Sayım ve Adres Yönetimi]
            Counter[Object Counter <br> 8-bit Sayıcı]
            AddrReg[RAM Adres Sayacı <br> 4-bit Pointer]
            AddrMux[Adres Çoklayıcı <br> MUX]
        end
        
        subgraph Memory [single_port_ram.v]
            RAM_Block[(16x8 Dağıtılmış RAM)]
        end
    end

    subgraph Çıkışlar [Donanım Göstergeleri]
        LEDs([6-Bit Onboard LED Bar])
    end

    %% Bağlantılar
    MZ80 -->|Asenkron| MZ_Edge
    BTN -->|Asenkron| BTN_Edge
    
    MZ_Edge -->|Tetikleme| Counter
    BTN_Edge -->|Yazma İzni / we| RAM_Block
    BTN_Edge -->|Adres Artır & Sıfırla| AddrReg
    
    Counter -->|Veri Girişi / din| RAM_Block
    AddrReg --> AddrMux
    BTN_Edge --> AddrMux
    
    AddrMux -->|Seçilen Adres / addr| RAM_Block
    RAM_Block -->|Okunan Veri / dout| LEDs
