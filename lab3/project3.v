// ==============================================================================
// 1. MODÜL: Saat Bölücü (Clock Divider)
// Açıklama: Yüksek frekanslı sistem saatini istenilen yavaşlıkta bir 'tick'
//           sinyaline dönüştürür.
// ==============================================================================
module clk_divider #(
    parameter HEDEF = 27_000_000
)(
    input wire clk,
    input wire rst_n,
    output reg tick
);

    reg [24:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= 25'd0;
            tick <= 1'b0;
        end else begin
            if (cnt == HEDEF - 1) begin
                cnt  <= 25'd0;
                tick <= 1'b1; // Hedefe ulaşıldığında 1 saat çevrimlik tetik
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end
        end
    end

endmodule

// ==============================================================================
// 2. MODÜL: Knight Rider (Kara Şimşek) Lojik Birimi
// Açıklama: Gelen 'tick' sinyaline göre LED pozisyonunu sağa ve sola kaydırır.
//           Aktif-düşük (Active-Low) LED mimarisine göre tasarlanmıştır.
// ==============================================================================
module knight_rider #(
    parameter W = 6  // Toplam LED Sayısı
)(
    input wire clk,
    input wire rst_n,
    input wire tick,    // clk_divider'dan gelen senkronizasyon sinyali
    output reg [W-1:0] led
);

    reg [3:0] pos;      // Mevcut aktif LED'in pozisyon indeksi
    reg dir;            // Yön Bayrağı -> 0: İleri/Sağa, 1: Geri/Sola

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos <= 4'd0;
            dir <= 1'b0;
        end else if (tick) begin
            if (dir == 1'b0) begin 
                // İleri (Sağa) Kaydırma
                if (pos == W - 1) begin
                    dir <= 1'b1;       // Son LED'e ulaşıldı, yönü tersine çevir
                    pos <= pos - 1'b1;
                end else begin
                    pos <= pos + 1'b1;
                end
            end else begin         
                // Geri (Sola) Kaydırma
                if (pos == 4'd0) begin
                    dir <= 1'b0;       // İlk LED'e ulaşıldı, yönü tersine çevir
                    pos <= pos + 1'b1;
                end else begin
                    pos <= pos - 1'b1;
                end
            end
        end
    end

    // Çıkış Mantığı: Sadece 'pos' değerine karşılık gelen bit '0' yapılır.
    // Örnek (pos=2): 1 << 2 = 000100 -> Değili (~) = 111011
    always @(*) begin
        led = ~(1 << pos);
    end

endmodule

// ==============================================================================
// 3. MODÜL: Top Modül (Ana Birleştirici)
// Açıklama: Alt modülleri (clk_divider ve knight_rider) örnekleyerek (instantiation)
//           birbirine bağlar ve sistemin donanım giriş/çıkışlarını tanımlar.
// ==============================================================================
module top (
    input wire clk,       // 27 MHz sistem saati
    input wire rst_n,     // Donanım reset butonu (Aktif-Düşük)
    output wire [5:0] led // 6-Bit LED çıkış veri yolu
);

    // Alt modüller arasında veri taşıyacak dahili sinyal (wire)
    wire tick;

    // 1. Clock Bölücü Örneklemesi
    // 27 MHz / 50 = Saniyede 50 kez (50 Hz) çalışan akıcı bir animasyon frekansı
    clk_divider #(.HEDEF(27_000_000 / 50)) u_clk (
        .clk    (clk),
        .rst_n  (rst_n),
        .tick   (tick)
    );

    // 2. Knight Rider Lojik Örneklemesi
    knight_rider #(.W(6)) u_kr (
        .clk    (clk),
        .rst_n  (rst_n),
        .tick   (tick),
        .led    (led)
    );

endmodule
