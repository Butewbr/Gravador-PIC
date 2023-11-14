// Escala de tempo 
`timescale 1ns/1ps

// Nome do módulo
module picwriter_tb;

// Sinais de interligação
reg a_tb, b_tb, clk_x; 
wire carry_tb, sum_tb;

// Instância a ser simulada
halfadd U0 (
  .a (a_tb), 
  .b (b_tb), 
  .sum (sum_tb), 
  .carry (carry_tb)
);

// Geração do clock
initial begin
  clk_x = 1'b0;  // Valor inicial do clock
  forever #5 clk_x = ~clk_x;  // Inverter o clock a cada 5ns para criar um ciclo de 10ns
end

// Simulação dos sinais a e b com o clock
initial begin
  // Espera um pouco antes de iniciar os sinais
  a_tb = 1'b0;
  b_tb = 1'b0;
  // Aguarde uma borda de subida do clock antes de mudar os valores
  @(posedge clk_x);
  a_tb = 1'b1;
  b_tb = 1'b0;

  @(posedge clk_x);
  a_tb = 1'b0;
  b_tb = 1'b1;

  @(posedge clk_x);
  a_tb = 1'b1;
  b_tb = 1'b1;
  
  // Adicione uma espera final para garantir que o último conjunto de sinais seja processado
  @(posedge clk_x);
end

// Fim do módulo
endmodule
