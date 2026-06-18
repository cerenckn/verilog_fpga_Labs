// ==============================================================================
// Açıklama     : FSM Tabanlı İki Yönlü Trafik Işığı Kontrolcüsü (Moore Tipi)
// Hedef Cihaz   : Gowin FPGA (27 MHz Dahili Osilatör)
// Logik Yapısı  : Aktif-Düşük (Active-Low) LED Sürücü
// ==============================================================================

module traffic_light (
    input wire clk,      // 27 MHz ana saat sinyali (Clock Girişi)
    input wire rst_n,    // Aktif-düşük sıfırlama sinyali (Reset - Buton 1)
    output reg [5:0] led // [5:3] -> Doğu-Batı (K,S,Y) | [2:0] -> Kuzey-Güney (K,S,Y)
);

    // ---- Parametreler ve Zaman Ayarları ----
    parameter CLK_FREQ   = 27_000_000; // Saat frekansı (27 MHz)
    localparam SURE_YESIL = 4'd10;      // Yeşil ışık süresi (10 saniye)
    localparam SURE_SARI  = 4'd3;       // Sarı ışık süresi (3 saniye)

    // ---- FSM Durum Tanımlamaları (One-Hot veya Binary) ----
    localparam S0_KG_YESIL = 2'b00,  // Kuzey-Güney: Yeşil  | Doğu-Batı: Kırmızı
               S1_KG_SARI  = 2'b01,  // Kuzey-Güney: Sarı   | Doğu-Batı: Kırmızı
               S2_DB_YESIL = 2'b10,  // Kuzey-Güney: Kırmızı| Doğu-Batı: Yeşil
               S3_DB_SARI  = 2'b11;  // Kuzey-Güney: Kırmızı| Doğu-Batı: Sarı

    // ---- İç Kaydediciler (Registers) ----
    reg [24:0] clk_cnt;
    reg tick;
    reg [1:0] state, next_state;
    reg [3:0] timer;
    
    wire timer_bitti = (timer == 0);

    // ---- 1. BLOK: Saat Bölücü (27 MHz -> 1 Hz Tick Üretimi) ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= 0;
            tick    <= 0;
        end else begin
            if (clk_cnt == (CLK_FREQ - 1)) begin
                clk_cnt <= 0;
                tick    <= 1; // 1 saniye dolduğunda tek çevrimlik tetikleme
            end else begin
                clk_cnt <= clk_cnt + 1;
                tick    <= 0;
            end
        end
    end

    // ---- 2. BLOK: Kombinasyonel Sonraki Durum Mantığı ----
    always @(*) begin
        next_state = state;
        case (state)
            S0_KG_YESIL: if (timer_bitti) next_state = S1_KG_SARI;
            S1_KG_SARI:  if (timer_bitti) next_state = S2_DB_YESIL;
            S2_DB_YESIL: if (timer_bitti) next_state = S3_DB_SARI;
            S3_DB_SARI:  if (timer_bitti) next_state = S0_KG_YESIL;
            default:     next_state = S0_KG_YESIL;
        endcase
    end

    // ---- 3. BLOK: Ardışıl Durum ve Zamanlayıcı Güncelleme ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0_KG_YESIL;
            timer <= SURE_YESIL - 1;
        end else if (tick) begin
            if (timer_bitti) begin
                state <= next_state;
                // Yeni duruma geçişte zamanlayıcı değerini yükle
                case (next_state)
                    S0_KG_YESIL, S2_DB_YESIL: timer <= SURE_YESIL - 1;
                    S1_KG_SARI,  S3_DB_SARI:  timer <= SURE_SARI - 1;
                    default:                  timer <= SURE_YESIL - 1;
                endcase
            end else begin
                timer <= timer - 1; // Geri sayım
            end
        end
    end

    // ---- 4. BLOK: Çıkış Logiği (Moore Şeması - Sadece Mevcut Duruma Bağlı) ----
    // Not: Donanım yapısı gereği '0' LED'i yakar, '1' söndürür (Active-Low).
    // LED Bit Sıralaması: [5]=DB_K, [4]=DB_S, [3]=DB_Y | [2]=KG_K, [1]=KG_S, [0]=KG_Y
    always @(*) begin
        case (state)
            S0_KG_YESIL: led = 6'b011_110; // DB: Kırmızı Yanıyor | KG: Yeşil Yanıyor
            S1_KG_SARI:  led = 6'b011_101; // DB: Kırmızı Yanıyor | KG: Sarı Yanıyor
            S2_DB_YESIL: led = 6'b110_011; // DB: Yeşil Yanıyor   | KG: Kırmızı Yanıyor
            S3_DB_SARI:  led = 6'b101_011; // DB: Sarı Yanıyor    | KG: Kırmızı Yanıyor
            default:     led = 6'b111_111; // Hata Durumu: Tüm LED'ler Sönük
        endcase
    end

endmodule
