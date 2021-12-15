module tb_cpu();
    logic [31:0] readdata;
    logic [31:0] writedata;
    logic reset;
    logic active;
    logic [31:0] register_v0;
    logic [31:0] address;
    logic write;
    logic read;
    logic waitrequest;
    logic [3:0] byteenable;
    logic clk;

    logic [7:0] r1;
    logic [7:0] r2;
    logic [7:0] r3;
    logic [7:0] r4;
    logic [7:0] w1;
    logic [7:0] w2;
    logic [7:0] w3;
    logic [7:0] w4;

    logic [7:0] RAM[0:400];
    initial begin
        //Data We Will Utilize:
        /*RAM[4] = 8'hFC;
        RAM[5] = 8'hF8;
        RAM[6] = 8'h3A;
        RAM[7] = 8'h5C;
        
        RAM[8] = 8'h52;
        RAM[9] = 8'h06;
        RAM[10] = 8'hAC;
        RAM[11] = 8'hE1;*/

        RAM[4] = 8'h00;
        RAM[5] = 8'h00;
        RAM[6] = 8'h00;
        RAM[7] = 8'hCC;
        
        RAM[8] = 8'h00;
        RAM[9] = 8'h00;
        RAM[10] = 8'h00;
        RAM[11] = 8'h0F;

        //LW $7, 4, $0          WORKING
            RAM[100] = 8'h8C;
            RAM[101] = 8'h07;
            RAM[102] = 8'h00;
            RAM[103] = 8'h04;
        //LW $8, 4, $0              WORKING
            RAM[104] = 8'h8C;
            RAM[105] = 8'h08;
            RAM[106] = 8'h00;
            RAM[107] = 8'h08;
        // AND $9 $7 $8           WORKING
            RAM[108] = 8'h01;
            RAM[109] = 8'h07;
            RAM[110] = 8'h48;
            RAM[111] = 8'h24;
        //SW $9, 12, $0         WORKING
            RAM[112] = 8'hAC;
            RAM[113] = 8'h09;
            RAM[114] = 8'h00;
            RAM[115] = 8'h0C;

    //LOAD TESTING
        /*//LW $1, 4, $0          WORKING
            RAM[100] = 8'h8C;
            RAM[101] = 8'h01;
            RAM[102] = 8'h00;
            RAM[103] = 8'h04;
        //LH $2, 4, $0              WORKING
            RAM[104] = 8'h84;
            RAM[105] = 8'h02;
            RAM[106] = 8'h00;
            RAM[107] = 8'h04;
        //LH $3, 6, $0              WORKING
            RAM[108] = 8'h84;
            RAM[109] = 8'h03;
            RAM[110] = 8'h00;
            RAM[111] = 8'h06;
        //LB $4, 4, $0          
            RAM[112] = 8'h80;
            RAM[113] = 8'h04;
            RAM[114] = 8'h00;
            RAM[115] = 8'h04;
        //LB $5, 5, $0          
            RAM[116] = 8'h80;
            RAM[117] = 8'h05;
            RAM[118] = 8'h00;
            RAM[119] = 8'h05;
        //LB $6, 6, $0          
            RAM[120] = 8'h80;
            RAM[121] = 8'h06;
            RAM[122] = 8'h00;
            RAM[123] = 8'h06;
        //LB $7, 7, $0          
            RAM[124] = 8'h80;
            RAM[125] = 8'h07;
            RAM[126] = 8'h00;
            RAM[127] = 8'h07;
        //LB $8, 11, $0          
            RAM[128] = 8'h80;
            RAM[129] = 8'h08;
            RAM[130] = 8'h00;
            RAM[131] = 8'h0B;
        //LBU $9, 11, $0          
            RAM[132] = 8'h90;
            RAM[133] = 8'h09;
            RAM[134] = 8'h00;
            RAM[135] = 8'h0B;
        //LWL $13, 8, $0          
            //RAM[136] = 8'h88;
            //RAM[137] = 8'h0D;
            //RAM[138] = 8'h00;
            //RAM[139] = 8'h08;
        //LWR $8, 10, $0           //5206ACE1 -> e1ff5206
            RAM[136] = 8'h88;
            RAM[137] = 8'h08;
            RAM[138] = 8'h00;
            RAM[139] = 8'h0A;*/
    //STORE TESTING
        /*//LW $4, 4, $0          WORKING
            RAM[100] = 8'h8C;
            RAM[101] = 8'h04;
            RAM[102] = 8'h00;
            RAM[103] = 8'h04;
        //LW $5, 8, $0          WORKING
            RAM[104] = 8'h8C;
            RAM[105] = 8'h05;
            RAM[106] = 8'h00;
            RAM[107] = 8'h08;
        //SW $4, 12, $0         WORKING
            RAM[108] = 8'hAC;
            RAM[109] = 8'h04;
            RAM[110] = 8'h00;
            RAM[111] = 8'h0C;
        //SH $4, 16, $0         WORKING
            RAM[112] = 8'hA4;
            RAM[113] = 8'h04;
            RAM[114] = 8'h00;
            RAM[115] = 8'h10;
        //SH $5, 18, $0         WORKING
            RAM[116] = 8'hA4;
            RAM[117] = 8'h05;
            RAM[118] = 8'h00;
            RAM[119] = 8'h12;
        //SB $4, 20, $0         WORKING  
            RAM[120] = 8'hA0;
            RAM[121] = 8'h05;
            RAM[122] = 8'h00;
            RAM[123] = 8'h17;*/
        //SB $4, 21, $0
            //RAM[120] = 8'h;
            //RAM[121] = 8'h;
            //RAM[122] = 8'h;
            //RAM[123] = 8'h;
        //SB $4, 22, $0
            //RAM[120] = 8'h;
            //RAM[121] = 8'h;
            //RAM[122] = 8'h;
            //RAM[123] = 8'h;
        //SB $4, 23, $0
            //RAM[120] = 8'h;
            //RAM[121] = 8'h;
            //RAM[122] = 8'h;
            //RAM[123] = 8'h;
    //ADD TESTING
        //LH $1, 4, $0              WORKING
            //RAM[104] = 8'h84;
            //RAM[105] = 8'h01;
            //RAM[106] = 8'h00;
            //RAM[107] = 8'h04;
        //LH $2, 8, $0              WORKING
            //RAM[108] = 8'h84;
            //RAM[109] = 8'h02;
            //RAM[110] = 8'h00;
            //RAM[111] = 8'h04;
        //ADDU $3 $1 $2         R3 = 8AE6FF4E   WORKING
            //RAM[112] = 8'h00;
            //RAM[113] = 8'h22;
            //RAM[114] = 8'h18;
            //RAM[115] = 8'h21;
        //SW $3, 12, $0         WORKING
            //RAM[116] = 8'hAC;
            //RAM[117] = 8'h03;
            //RAM[118] = 8'h00;
            //RAM[119] = 8'h0C;
    /*//
        //DIV $1 $4 ($1/$4)  -> 5c3af8fc/2d8ef2aa = 2 remainder 11D13A8. HI = 11D13A8, LO = 2   WORKING
            RAM[116] = 8'h1A;
            RAM[117] = 8'h00;
            RAM[118] = 8'h24;
            RAM[119] = 8'h00;
        //MFHI $5               R5 = HI = 11D13A8    WORKING
            RAM[120] = 8'h10;
            RAM[121] = 8'h28;
            RAM[122] = 8'h00;
            RAM[123] = 8'h00;
        //MFLO $6               R6 = LO = 2          WORKING
            RAM[124] = 8'h12;
            RAM[125] = 8'h30;
            RAM[126] = 8'h00;
            RAM[127] = 8'h00;
        //MTHI $3               HI = $3
            RAM[128] = 8'h11;
            RAM[129] = 8'h00;
            RAM[130] = 8'h60;
            RAM[131] = 8'h00;
        //MTLO $4               LO = $4
            RAM[132] = 8'h13;  
            RAM[133] = 8'h00;
            RAM[134] = 8'h80;
            RAM[135] = 8'h00;
        //MFHI $5               $5 = HI     WORKING
            RAM[136] = 8'h10;
            RAM[137] = 8'h28;
            RAM[138] = 8'h00;
            RAM[139] = 8'h00;
        //MFLO $6               $6 = LO     WORKING
            RAM[140] = 8'h12;
            RAM[141] = 8'h30;
            RAM[142] = 8'h00;
            RAM[143] = 8'h00;
        //LB $5, 6, $0          $5 = 3A     WORKING
            RAM[144] = 8'h06;
            RAM[145] = 8'h00;
            RAM[146] = 8'h05;
            RAM[147] = 8'h80;
        //LH $6, 10, $0          $6 = 2EAC    WORKING
            RAM[148] = 8'h0A;
            RAM[149] = 8'h00;
            RAM[150] = 8'h06;
            RAM[151] = 8'h84;
        //MULT $6 $3            HI = 00001952, LO = D5138C68     FIXME:NOT WORKING LO is wrong?
            RAM[152] = 8'h18;
            RAM[153] = 8'h00;
            RAM[154] = 8'hC3;
            RAM[155] = 8'h00;
        //MFHI $7               $7 = HI     WORKING
            RAM[156] = 8'h10;
            RAM[157] = 8'h38;
            RAM[158] = 8'h00;
            RAM[159] = 8'h00;
        //MFLO $8               $8 = LO      WORKING
            RAM[160] = 8'h12;
            RAM[161] = 8'h40;
            RAM[162] = 8'h00;
            RAM[163] = 8'h00;
        //MULTU $6 $5            HI = 00000000, LO = 000A92F8     WORKING
            RAM[164] = 8'h19;
            RAM[165] = 8'h00;
            RAM[166] = 8'hA6;
            RAM[167] = 8'h00;
        //MFLO $5               $5 = LO      WORKING
            RAM[168] = 8'h12;
            RAM[169] = 8'h28;
            RAM[170] = 8'h00;
            RAM[171] = 8'h00;
        // AND $9 $7 $8         $9 = d5138820   WORKING
            RAM[172] = 8'h24;
            RAM[173] = 8'h48;
            RAM[174] = 8'hE8;
            RAM[175] = 8'h00;
        // OR $10 $1 $3         $10 = defefffe  WORKING
            RAM[176] = 8'h25;
            RAM[177] = 8'h50;
            RAM[178] = 8'h23;
            RAM[179] = 8'h00;
        // XOR $11 $6 $7        $11 = ffffc40a  WORKING
            RAM[180] = 8'h26;
            RAM[181] = 8'h58;
            RAM[182] = 8'hC7;
            RAM[183] = 8'h00;
        //SLT $12 $11 $4        $12 = 1 since signed. $11 is very negative.     WORKING
            RAM[184] = 8'h2A;
            RAM[185] = 8'h60;
            RAM[186] = 8'h64;
            RAM[187] = 8'h01;
        //SLTU $13 $11 $4       $12 = 0 since unsigned. $11 is very positive.   WORKING
            RAM[188] = 8'h2B;
            RAM[189] = 8'h68;
            RAM[190] = 8'h64;
            RAM[191] = 8'h01;
        //BEQ $13 $14 0x7       Jump to 220 but still do the ADDI after. Then move onto the ADDIU  WORKING
            RAM[192] = 8'h06;
            RAM[193] = 8'h00;
            RAM[194] = 8'hAE;
            RAM[195] = 8'h11;
        //ADDIU $13 $6 0x50     $13 = 2ede      WORKING
            RAM[196] = 8'h32;
            RAM[197] = 8'h00;
            RAM[198] = 8'hCD;
            RAM[199] = 8'h24;
        //ANDI $14 $7 0x214     $14 = 203       WORKING
            RAM[220] = 8'h14;
            RAM[221] = 8'h02;
            RAM[222] = 8'hEE;
            RAM[223] = 8'h30;
        //BGTZ $7 0x3           Should not jump to 240 as signed of $7 is less than 0.  WORKING?
            RAM[224] = 8'h03;
            RAM[225] = 8'h00;
            RAM[226] = 8'hE0;
            RAM[227] = 8'h1C;
        //BGTZ $4 0x5           Should jump to 252 as signed of $4 is greater than 0. Will do 232 first.    WORKING
            RAM[228] = 8'h05;
            RAM[229] = 8'h00;
            RAM[230] = 8'h80;
            RAM[231] = 8'h1C;
        //ORI $15 $5 0x1249     $15 = a92f9     WORKING 
            RAM[232] = 8'h29;
            RAM[233] = 8'h14;
            RAM[234] = 8'hAF;
            RAM[235] = 8'h34;
        //XORI $16 $5 0x1249    $16 = a80b1     WORKING
            RAM[252] = 8'h49;
            RAM[253] = 8'h12;
            RAM[254] = 8'hB0;
            RAM[255] = 8'h38;
        */
    end

    initial begin
        clk=0;
        repeat (200) begin
            #1;
            clk=!clk;
        end

        $display("%d %h",12, RAM[12]);
        $display("%d %h",13, RAM[13]);
        $display("%d %h",14, RAM[14]);
        $display("%d %h",15, RAM[15]);
        /*$display("%d %h",16, RAM[16]);
        $display("%d %h",17, RAM[17]);
        $display("%d %h",18, RAM[18]);
        $display("%d %h",19, RAM[19]);
        $display("%d %h",20, RAM[20]);
        $display("%d %h",21, RAM[21]);
        $display("%d %h",22, RAM[22]);
        $display("%d %h",23, RAM[23]);*/

        $finish(0);
    end

    initial begin
        waitrequest=0;
        reset=0;
        repeat (100) begin
            #2;
            //$display("Address %d\n", address - 3217031068);
            //$display("waitrequest %d\n", waitrequest);
            //$display("Combined Output of CPU: %d", {r1, r2, r3, r4});
            //$display("%d %h",8, RAM[8]);
            //$display("%d %h",9, RAM[9]);
            //$display("%d %h",10, RAM[10]);
            //$display("%d %h",11, RAM[11]);
            //if (write) begin
            //    $display("Writing at location: %d with data %h with byteenable %b", address, writedata, byteenable);
            //end
        end
        /*repeat (10) begin
            waitrequest = 1;
            $display("Address %d\n", address - 3217031068);
            $display("waitrequest %d\n", waitrequest);
            #2;
        end
        repeat (20) begin
            waitrequest = 0;
            $display("Address %d\n", address - 3217031068);
            $display("waitrequest %d\n", waitrequest);
            #2;
        end*/
    end

    always_ff @(posedge clk) begin
        if (read) begin
            r4 = (address > 3217031167) ? (RAM[address - 3217031068]) : (RAM[address]) * (byteenable[3]);
            r3 = (address > 3217031167) ? (RAM[address + 1 - 3217031068]) : (RAM[address + 1]) * (byteenable[2]);
            r2 = (address > 3217031167) ? (RAM[address + 2 - 3217031068]) : (RAM[address + 2]) * (byteenable[1]);
            r1 = (address > 3217031167) ? (RAM[address + 3 - 3217031068]) : (RAM[address + 3]) * (byteenable[0]);
            readdata = {r4, r3, r2, r1};
        end
        if (write) begin
            if (byteenable[0]) RAM[address + 3] <= writedata[7:0];
            if (byteenable[1]) RAM[address + 2] <= writedata[15:8];
            if (byteenable[2]) RAM[address + 1] <= writedata[23:16];
            if (byteenable[3]) RAM[address] <= writedata[31:24];
        end
    end

    mips_cpu_bus mips_cpu_bus(  .clk(clk), 
                                .reset(reset), 
                                .active(active), 
                                .register_v0(register_v0), 
                                .address(address), 
                                .write(write), 
                                .read(read), 
                                .waitrequest(waitrequest), 
                                .writedata(writedata), 
                                .byteenable(byteenable), 
                                .readdata(readdata));

endmodule
