// ==============================================================================
// Dosya Adı     : top.v
// Açıklama     : MZ80 Kızılötesi Sensör Tabanlı Nesne Sayıcı ve RAM Günlükçüsü
// Hedef Cihaz   : Gowin FPGA (27 MHz Dahili Osilatör)
// Fonksiyon     : Sensörden gelen nesneleri sayar, buton tetiklemesiyle veriyi
//                RAM'e kaydeder ve kaydedilen son veriyi LED'lerde gösterir.
// ==============================================================================

module top (
    input wire clk,          // 27 MHz Sistem Saat Sinyali
    input wire rst_n,        // Donanımsal Sıfırlama (Aktif-Düşük - S1 Butonu)
    input wire mz80_out,     // MZ80 Kızılötesi Sensör Girişi (Aktif-Düşük)
    input wire btn_kaydet,   // RAM Kayıt Tetikleme Butonu (Aktif-Düşük - S2 Butonu)
    output wire [5:0] led    // Onboard 6-Bit LED Çıkışı (Aktif-Düşük)
);

    // ---- İç Bağlantılar ve Kaydediciler ----
    reg [7:0] object_count;  // Mevcut üretim bandı/nesne sayacı
    reg [3:0] ram_addr;      // RAM Adres İşaretçisi (Maksimum 16 Kayıt Slotu)
    wire [7:0] ram_dout;     // RAM'den okunan veri hattı
    
    // Senkronizasyon ve Metastabilite Önleyici Register Hatları
    reg mz80_q1, mz80_q2;
    reg btn_q1, btn_q2;
    
    // ---- 1. BLOK: Metastabilite Önleme ve Kenar Yakalama ----
    // Asenkron harici girişleri sistem saatine senkronize eder.
    always @(posedge clk or megedge rst_n) begin
        if (!rst_n) begin
            mz80_q1 <= 1'b1; mz80_q2 <= 1'b1;
            btn_q1  <= 1'b1; btn_q2  <= 1'b1;
        end else begin
            mz80_q1 <= mz80_out;  
            mz80_q2 <= mz80_q1;
            btn_q1  <= btn_kaydet; 
            btn_q2  <= btn_q1;
        end
    end

    // Düşen Kenar (Falling Edge) Algılayıcıları (0'a düştüğü anı yakalar)
    wire mz80_edge = ~mz80_q1 & mz80_q2; 
    wire btn_edge  = ~btn_q1  & btn_q2; 

    // ---- 2. BLOK: RAM Adres ve Çoklayıcı (Multiplexer) Yönetimi ----
    // Yazma esnasında güncel adresi, okuma esnasında ise en son kayıt yapılan adresi gösterir.
    wire [3:0] current_addr = btn_edge ? ram_addr : (ram_addr > 0 ? ram_addr - 1'b1 : 4'd0);

    // ---- 3. BLOK: RAM Modülünün Örneklenmesi (Instantiation) ----
    single_port_ram #(.DATA_W(8), .ADDR_W(4)) u_ram (
        .clk(clk),
        .we(btn_edge),       // Butona basıldığı an 1 saat çevrimlik yazma izni
        .addr(current_addr), 
        .din(object_count),  // O ana kadar sayılan nesne miktarını gönder
        .dout(ram_dout)      // Okunan veriyi çıkış hattına aktar
    );

    // ---- 4. BLOK: Sayaç ve Kontrol Mantığı ----
    always @(posedge clk or megedge rst_n) begin
        if (!rst_n) begin
            object_count <= 8'd0;
            ram_addr     <= 4'd0;
        end else begin
            if (btn_edge) begin
                ram_addr     <= ram_addr + 1'b1;  // Bir sonraki kayıt slotuna geç
                object_count <= 8'd0;             // Kaydedilen sayacı hemen sıfırla
            end else if (mz80_edge) begin
                object_count <= object_count + 1'b1; // Nesne algılandı, sayacı artır
            end
        end
    end

    // ---- 5. BLOK: Çıkış Ataması ----
    // Henüz hiçbir kayıt yapılmadıysa (ram_addr == 0) tüm LED'leri söndür (Active-Low: 111111).
    // Kayıt varsa RAM'den okunan değerin alt 6 bitini tersleyerek görselleştir.
    assign led = (ram_addr == 4'd0) ? 6'b111111 : ~ram_dout[5:0];

endmodule
