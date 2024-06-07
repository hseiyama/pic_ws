mix_sam01.X（実機確認）
　・MCC Timer2の試行
mix_sam02.X（実機確認）
　・Adccの試行
　・Pwm1の試行
　・Uart3のFIFOバッファ適用
mix_sam03.X（実機確認）
　・モジュール分割（UART,ADCC,PWM1）
mix_sam04.X（実機確認）
　・I2c1(割り込み)の試行
　・Spi1(ポーリング)の試行
　　【注意1】SPI1_BufferRead()→SPI1_BufferWrite()で動作不備あり。
　　【注意2】SPI1_BufferWrite()を使うと、末尾に余計な波形が出る。
　　【補足1】***Exchange(5.69us)は***Write(3.06us)と比べ少し遅い。
