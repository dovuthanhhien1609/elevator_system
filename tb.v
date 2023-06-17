`timescale 10ns/1ns
module tb ();
parameter N = 8;
reg                     clk;
reg                     rst_n;
reg      [N-1:0]        button_up;
reg      [N-1:0]        button_down;
reg                     button_close;
reg                     button_open;
reg      [N-1:0]        button_select_floor;
reg      [N-1:0]        floor_sensor;
reg                     overweight_sensor;
reg                     fire_alert;
wire                    close_door;
wire                    open_door;
wire                    motor_up;
wire                    motor_down;
wire                    direction_up;
wire                    direction_down;
elevator_controller #(.N(8), .NUM_CLK_DELAY(4))
dut(
  .clk                (clk),
  .rst_n              (rst_n),
  .button_up          (button_up),
  .button_down        (button_down),
  .button_close       (button_close),
  .button_open        (button_open),
  .button_select_floor(button_select_floor),
  .floor_sensor       (floor_sensor),
  .overweight_sensor  (overweight_sensor),
  .fire_alert         (fire_alert),
  .close_door         (close_door),
  .open_door          (open_door),
  .motor_up           (motor_up),
  .motor_down         (motor_down),
  .direction_up       (direction_up),
  .direction_down     (direction_down)
  );

initial begin 
  clk = 0;
  rst_n = 1;
  button_up = 0;
  button_down = 0;
  button_close = 0;
  button_open = 0;
  fire_alert = 0;
  button_select_floor = 0;
  floor_sensor = 1;
  overweight_sensor = 0;
  @(negedge clk) rst_n = 0;
  @(negedge clk) rst_n = 1;
  button_select_floor[3] = 1;
  repeat(3) begin
    repeat(2) @(negedge clk);
    // floor_sensor = floor_sensor << 1;
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
    // repeat(10) @(negedge clk);
  end
  wait(close_door == 1) button_select_floor = 8'b00000001;
  repeat(3) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  wait(close_door == 1) button_down[7] = 1;
  button_select_floor = 0;
  repeat(7) begin
    repeat(2) @(negedge clk);
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
  end
  wait(close_door == 1) button_select_floor = 8'b00000001;
  button_down[7] = 0;
  repeat(7) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  button_open = 1;
  repeat(10) @(negedge clk);
  button_open = 0;
  wait(close_door == 1) button_select_floor = 0;
  repeat(10) @(negedge clk);
  button_select_floor[4] = 1;
  repeat(4) begin
    repeat(2) @(negedge clk);
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
  end
  wait(close_door == 1) button_select_floor = 8'b10000000;
  repeat(3) begin
    repeat(2) @(negedge clk);
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
  end

  wait(close_door == 1) button_select_floor = 8'b00010000;
  repeat(3) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  button_select_floor = 0;
  button_up[1] = 1;
  repeat(3) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  wait(close_door == 1) button_select_floor = 8'b00010000; button_up[1] = 0;
  repeat(3) begin
    repeat(2) @(negedge clk);
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
  end
  wait(close_door == 1) button_select_floor = 8'b00000001;
  repeat(4) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  wait(close_door == 1) button_select_floor = 8'b00100000;
  button_down[3] = 1;
  repeat(5) begin
    repeat(2) @(negedge clk);
    wait(motor_up == 1) floor_sensor = floor_sensor << 1;
  end
  wait(close_door == 1) button_select_floor[5] = 0;
  repeat(2) begin
    repeat(2) @(negedge clk);
    wait(motor_down == 1) floor_sensor = floor_sensor >> 1;
  end
  wait(close_door == 1) button_down = 0;
  $stop;
end

always #5 clk = ~clk;

endmodule