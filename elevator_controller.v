module elevator_controller #(
  parameter N = 8,
  parameter NUM_CLK_DELAY = 1024
  )(
  input                    clk,    // Clock
  input                    rst_n,  // Asynchronous reset active low
  input  [N-1:0]           button_up,
  input  [N-1:0]           button_down,
  input                    button_close,
  input                    button_open,
  input  [N-1:0]           button_select_floor,
  input  [N-1:0]           floor_sensor,
  input                    overweight_sensor,
  input                    fire_alert,
  output                   close_door,
  output                   open_door,
  output                   motor_up,
  output                   motor_down,
  output                   direction_up,
  output                   direction_down
);
wire cnt_eq_0, dec_cnt, init_cnt;
wire [2:0] current_floor;

control_unit #(.N(N)) control_dut(
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
.cnt_eq_0           (cnt_eq_0),
.close_door         (close_door),
.open_door          (open_door),
.current_floor      (current_floor),
.motor_up           (motor_up),
.motor_down         (motor_down),
.direction_up       (direction_up),
.direction_down     (direction_down),
.dec_cnt            (dec_cnt),
.init_cnt           (init_cnt)
  );

datapath #(.NUM_CLK_DELAY(NUM_CLK_DELAY)) datapath_dut(
.clk     (clk),
.rst_n   (rst_n),
.dec_cnt (dec_cnt),
.init_cnt(init_cnt),
.cnt_eq_0(cnt_eq_0)
  );

endmodule

module control_unit #(
  parameter N = 8
  )(
  input                         clk,    // Clock
  input                         rst_n,  // Asynchronous reset active low
  input       [N-1:0]           button_up,
  input       [N-1:0]           button_down,
  input                         button_close,
  input                         button_open,
  input       [N-1:0]           button_select_floor,
  input       [N-1:0]           floor_sensor,
  input                         overweight_sensor,
  input                         fire_alert,
  input                         cnt_eq_0,
  output reg                    close_door,
  output reg                    open_door,
  output reg  [$clog2(N)-1:0]   current_floor,
  output reg                    motor_up,
  output reg                    motor_down,
  output reg                    direction_up,
  output reg                    direction_down,
  output reg                    dec_cnt,
  output reg                    init_cnt
);
  localparam  CHECK = 2'b00,
              UP    = 2'b01,
              DOWN  = 2'b10,
              OPEN  = 2'b11;

reg [1:0] state, next_state;
reg rq_at_lower, rq_at_higher, rq_at_curr, up_rq_curr, down_rq_curr;
reg [N-1:0] rq_floor;
reg down_floor, up_floor;
reg [$clog2(N)-1:0] current_floor_reg;
integer i;

always @(posedge clk or negedge rst_n) begin : proc_state
  if(~rst_n) begin
    state <= 0;
  end else begin
    state <= next_state;
  end
end

always @(posedge clk or negedge rst_n) begin : proc_current_floor_reg
  if(~rst_n) begin
    current_floor_reg <= 0;
  end else begin
    if (current_floor_reg != current_floor) begin
      current_floor_reg <= current_floor;
    end
  end
end

always @(*) begin
 if (current_floor == current_floor_reg + 1) begin
   up_floor = 1;
   // direction_up = 1;
 end else begin
  up_floor = 0;
  // direction_up = 0;
 end
 if (current_floor == current_floor_reg - 1) begin
   down_floor = 1;
   // direction_down = 1;
 end else begin 
  down_floor = 0;
  // direction_down = 0;
 end 
end

always @(posedge clk or negedge rst_n) begin : proc_direction_up
  if(~rst_n) begin
    direction_up <= 0;
    direction_down <= 0;
  end 
  else if (up_floor) begin
    if (current_floor != N-1) begin
      direction_up <= 1;
      direction_down <= 0;
    end else begin 
      direction_up <= 0;
      direction_down <= 0;
    end
  end 
  else if (down_floor) begin
    if (current_floor != 0) begin
      direction_up <= 0;
      direction_down <= 1;
    end else begin 
      direction_up <= 0;
      direction_down <= 0;
    end
  end
  else if (direction_up) begin
    if (up_rq_curr | rq_at_higher)begin 
      direction_up <= 1;
      direction_down <= 0;
    end else begin 
      direction_up <= 0;
      direction_down <= 0;
    end
  end
  else if (direction_down) begin
    if (down_rq_curr | rq_at_lower)begin 
      direction_up <= 0;
      direction_down <= 1;
    end else begin 
      direction_up <= 0;
      direction_down <= 0;
    end
  end
  else begin 
    direction_up <= 0;
    direction_down <= 0;
  end
end

always @(*) begin
  for (i = 0; i < N; i=i+1) begin
    if (floor_sensor[i]==1) begin
      current_floor = i;
    end
  end
end

always @(*) begin
  rq_at_curr = 0;
  up_rq_curr = 0;
  down_rq_curr = 0;
  rq_at_lower = 0;
  rq_at_higher = 0;
  for (i = 0; i < N; i=i+1) begin
    rq_floor[i] = button_select_floor[i] | button_up[i] | button_down[i];
  end
  for (i = 0; i < N; i=i+1) begin
    if (rq_floor[i] == 1) begin
      if(current_floor == i) begin 
        rq_at_curr = 1;
        if (button_up[i]) begin
          up_rq_curr = 1;
        end
        if (button_down[i]) begin
          down_rq_curr = 1;
        end
      end
      if(current_floor > i) rq_at_lower = 1;
      if(current_floor < i) rq_at_higher = 1;
    end
  end
end

always @(*) begin
  close_door = 0;
  open_door = 0;
  // direction_up = 0;
  // direction_down = 0;
  motor_up = 0;
  motor_down = 0;
  dec_cnt = 0;
  init_cnt = 0;
  next_state = CHECK;
  case (state)
  CHECK: begin
    if (fire_alert) begin
      next_state = OPEN;
    end
    else if (rq_at_curr) begin
      if (up_rq_curr) begin
        if (direction_down != 1) begin
          next_state = OPEN;
          init_cnt = 1;
        end else next_state = CHECK;
      end 
      else if (down_rq_curr) begin
        if (direction_up != 1) begin
          next_state = OPEN;
          init_cnt = 1;
        end
      end 
      else begin 
        next_state = OPEN;
        init_cnt = 1;
      end 
    end 
    else if (rq_at_higher) begin
        if (direction_down != 1) begin
          next_state = UP;
        end
    end
    else if (rq_at_lower) begin
        if (direction_up != 1) begin
          next_state = DOWN;
        end else next_state = CHECK;
    end 
    else begin 
        next_state = CHECK;
    end
  end
  OPEN: begin 
    close_door = 0;
    open_door = 1;
    if (overweight_sensor) begin
      next_state = OPEN;
    end else if (button_open) begin
      next_state = OPEN;
    end else if (button_close) begin
      close_door = 1;
      open_door = 0;
      next_state = CHECK;
    end else if (cnt_eq_0) begin
      close_door = 1;
      open_door = 0;
      next_state = CHECK;
    end else begin 
      dec_cnt = 1;
      next_state = OPEN;
    end
  end
  UP: begin 
    // direction_up = 1;
    motor_up = 1;
    if (up_floor) begin
      next_state = CHECK;
    end else next_state = UP;
  end
  DOWN: begin 
    // direction_down = 1;
    motor_down = 1;
    if (down_floor) begin
      next_state = CHECK;
    end else next_state = DOWN;
  end
  endcase
end
endmodule

module datapath #(
  parameter NUM_CLK_DELAY = 1024
  )(
  input clk,
  input rst_n,
  input dec_cnt,
  input init_cnt,
  output cnt_eq_0
);
reg [NUM_CLK_DELAY-1:0] cnt;

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    cnt <= 0;
  end else begin
    if (init_cnt) begin
      cnt <= NUM_CLK_DELAY;
    end else if (dec_cnt) begin
      cnt <= cnt - 1;
    end
  end
end
assign cnt_eq_0 = cnt==0;
endmodule