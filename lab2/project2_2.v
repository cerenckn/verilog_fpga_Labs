// ==============================================================================
// Açıklama     : FSM Tabanlı Basit Otomat (Vending Machine) Kontrolcüsü
// Hedef Cihaz   : Gowin FPGA (27 MHz Dahili Osilatör)
// Fonksiyon     : Hedef bakiye olan 10 TL'ye ulaşıldığında ürün çıkışı verir.
// ==============================================================================

module vending_machine (
    input wire clk,          // 27 MHz ana saat sinyali (Clock Girişi)
    input wire rst_n,        // Aktif-düşük sıfırlama sinyali (Reset)
    input wire btn_5_raw,    // 5 TL girişi için buton sinyali (Ham Sinyal)
    input wire btn_10_raw,   // 10 TL girişi için buton sinyali (Ham Sinyal)
    output reg urun_ver,     // Ürün dağıtım mekanizması çıkışı (1: Ürün Ver)
    output reg [2:0] led     // Bakiye durumunu gösteren 3-bit LED bar
);

    // ---- FSM Durum Tanımlamaları ----
    localparam S_BAKIYE_0  = 2'b00; // Başlangıç durumu, bakiye: 0 TL
    localparam S_BAKIYE_5  = 2'b01; // Bakiye: 5 TL
    localparam S_BAKIYE_10 = 2'b10; // Hedef bakiye: 10 TL (Ürün verme fazı)

    reg [1:0] state, next_state;

    // ---- Giriş Sinyalleri İçin Yükselen Kenar Algılama (Edge Detection) ----
    // Butona basılı tutulduğunda FSM'in sürekli para eklemesini engeller, 
    // sadece basıldığı ilk çevrimi (1 clock cycle) yakalar.
    reg btn_5_d, btn_10_d; 
    wire btn_5  = btn_5_raw  & ~btn_5_d;  // 5 TL Buton Yükselen Kenar Tetiklemesi
    wire btn_10 = btn_10_raw & ~btn_10_d; // 10 TL Buton Yükselen Kenar Tetiklemesi

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_5_d  <= 1'b0;
            btn_10_d <= 1'b0;
        end else begin
            btn_5_d  <= btn_5_raw;
            btn_10_d <= btn_10_raw;
        end
    end

    // ---- 1. BLOK: Durum Hafızası (Ardışıl Mantık) ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= S_BAKIYE_0;
        else 
            state <= next_state;
    end

    // ---- 2. BLOK: Kombinasyonel Sonraki Durum ve Çıkış Mantığı ----
    always @(*) begin
        // Latch (Mandal) oluşumunu engellemek için varsayılan değerlerin atanması
        next_state = state; 
        urun_ver   = 1'b0;  
        led        = 3'b000;

        case (state)
            S_BAKIYE_0: begin
                led = 3'b001; // Sistem hazır, başlangıç LED'i aktif
                if (btn_5)      
                    next_state = S_BAKIYE_5;
                else if (btn_10) 
                    next_state = S_BAKIYE_10;
            end

            S_BAKIYE_5: begin
                led = 3'b011; // 5 TL yüklendiğini gösteren iki LED aktif
                if (btn_5)      
                    next_state = S_BAKIYE_10;
                else if (btn_10) 
                    next_state = S_BAKIYE_10; // Para üstü mekanizması olmadığından doğrudan hedefe gider
            end

            S_BAKIYE_10: begin
                led      = 3'b111; // Bakiye tamamlandı, tüm LED'ler aktif
                urun_ver = 1'b1;   // Ürün çıkarma sinyalini tetikle
                next_state = S_BAKIYE_0; // İşlem bitince bakiyeyi sıfırla ve başa dön
            end

            default: begin
                next_state = S_BAKIYE_0;
                led        = 3'b000;
            end
        endcase
    end

endmodule
