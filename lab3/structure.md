## 🏗 Sistem Blok Şeması (RTL Mimarisi)-Project3--example

Aşağıdaki diyagram, hiyerarşik modül bağlantılarını ve donanım sinyal akışını göstermektedir:

```mermaid
graph TD
    subgraph top [Top Modül - Sistem Çerçevesi]
        direction TB
        
        CLK([Sistem Saati - 27 MHz]) --> DIV
        CLK --> KR
        RST([Reset Butonu - rst_n]) --> DIV
        RST --> KR
        
        DIV[clk_divider Modülü <br> Hedef: 50 Hz] -- "tick (Tetik Sinyali)" --> KR[knight_rider Modülü <br> W: 6 Bit]
        
        KR -- "led[5:0]" --> OUT([Fiziksel LED Pinleri])
    end



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
