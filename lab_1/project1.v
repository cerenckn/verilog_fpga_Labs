module led (
    input sys_clk,          // Sistem saat frekansı (Clock) - Örn: 27MHz
    input sys_rst_n,        // Aktif düşük reset pini (Active-low Reset)
    output reg [2:0] led    // 3-Bit RGB LED çıkışı (110: Mavi, 101: Yeşil, 011: Kırmızı)
);

// 0.5 saniyelik gecikme için 24-bit sayaç (Counter)
// 27MHz saat hızında 0.5 saniye = 13,500,000 döngü (1349_9999'a kadar sayar)
reg [23:0] counter;

// Sayaç Bloğu
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        counter <= 24'd0;                           // Reset durumunda sayacı sıfırla
    else if (counter < 24'd1349_9999)               
        counter <= counter + 1'b1;                  // 0.5 sn dolana kadar sayacı 1 artır
    else
        counter <= 24'd0;                           // Süre dolduğunda sayacı tekrar sıfırla
end

// LED Kontrol Bloğu
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        led <= 3'b110;                              // Başlangıç durumu: Mavi LED yanar
    else if (counter == 24'd1349_9999)               
        led[2:0] <= {led[1:0], led[2]};             // 0.5 saniyede bir bitleri sola kaydır (Chaser efekti)
    else
        led <= led;                                 // Süre dolmadıysa mevcut durumu koru
end

endmodule
