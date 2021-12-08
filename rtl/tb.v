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

    logic [7:0] RAM[0:999];
    initial begin
        //Data We Will Utilize:
            RAM[4] = 8'hFC;
            RAM[5] = 8'hF8;
            RAM[6] = 8'h3A;
            RAM[7] = 8'h5C;

            RAM[8] = 8'h52;
            RAM[9] = 8'h06;
            RAM[10] = 8'hAC;
            RAM[11] = 8'h2E;

        //LW $1, 4, $0          WORKING
            RAM[500] = 8'h04;
            RAM[501] = 8'h00;
            RAM[502] = 8'h01;
            RAM[503] = 8'h8C;
        //LW $2, 8, $0          WORKING
            RAM[504] = 8'h08;
            RAM[505] = 8'h00;
            RAM[506] = 8'h02;
            RAM[507] = 8'h8C;
        //ADDU $3 $1 $2         R3 = 8AE6FF4E   WORKING
            RAM[508] = 8'h21;
            RAM[509] = 8'h18;
            RAM[510] = 8'h22;
            RAM[511] = 8'h00;  
        //SUBU $4 $1 $2 ($1-$2) R4 = 2D8EF2AA   WORKING
            RAM[512] = 8'h23;
            RAM[513] = 8'h20;
            RAM[514] = 8'h22;
            RAM[515] = 8'h00;
        //DIV $1 $4 ($1/$4)  -> 5c3af8fc/2d8ef2aa = 2 remainder 11D13A8. HI = 11D13A8, LO = 2   WORKING
            RAM[516] = 8'h1A;
            RAM[517] = 8'h00;
            RAM[518] = 8'h24;
            RAM[519] = 8'h00;
        //MFHI $5               R5 = HI = 11D13A8    WORKING
            RAM[520] = 8'h10;
            RAM[521] = 8'h28;
            RAM[522] = 8'h00;
            RAM[523] = 8'h00;
        //MFLO $6               R6 = LO = 2          WORKING
            RAM[524] = 8'h12;
            RAM[525] = 8'h30;
            RAM[526] = 8'h00;
            RAM[527] = 8'h00;
        //MTHI $3               HI = $3
            RAM[528] = 8'h11;
            RAM[529] = 8'h00;
            RAM[530] = 8'h60;
            RAM[531] = 8'h00;
        //MTLO $4               LO = $4
            RAM[532] = 8'h13;  
            RAM[533] = 8'h00;
            RAM[534] = 8'h80;
            RAM[535] = 8'h00;
        //MFHI $5               $5 = HI     WORKING
            RAM[536] = 8'h10;
            RAM[537] = 8'h28;
            RAM[538] = 8'h00;
            RAM[539] = 8'h00;
        //MFLO $6               $6 = LO     WORKING
            RAM[540] = 8'h12;
            RAM[541] = 8'h30;
            RAM[542] = 8'h00;
            RAM[543] = 8'h00;
        //LB $5, 6, $0          $5 = 3A     WORKING
            RAM[544] = 8'h06;
            RAM[545] = 8'h00;
            RAM[546] = 8'h05;
            RAM[547] = 8'h80;
        //LH $6, 10, $0          $6 = 2EAC    WORKING
            RAM[548] = 8'h0A;
            RAM[549] = 8'h00;
            RAM[550] = 8'h06;
            RAM[551] = 8'h84;
        //MULT $6 $3            HI = 00001952, LO = D5138C68     FIXME: NOT WORKING LO is wrong?
            RAM[552] = 8'h18;
            RAM[553] = 8'h00;
            RAM[554] = 8'hC3;
            RAM[555] = 8'h00;
        //MFHI $7               $7 = HI     WORKING
            RAM[556] = 8'h10;
            RAM[557] = 8'h38;
            RAM[558] = 8'h00;
            RAM[559] = 8'h00;
        //MFLO $8               $8 = LO      WORKING
            RAM[560] = 8'h12;
            RAM[561] = 8'h40;
            RAM[562] = 8'h00;
            RAM[563] = 8'h00;
        //MULTU $6 $5            HI = 00000000, LO = 000A92F8     WORKING
            RAM[564] = 8'h19;
            RAM[565] = 8'h00;
            RAM[566] = 8'hA6;
            RAM[567] = 8'h00;
        //MFLO $5               $5 = LO      WORKING
            RAM[568] = 8'h12;
            RAM[569] = 8'h28;
            RAM[570] = 8'h00;
            RAM[571] = 8'h00;
        // AND $9 $7 $8         $9 = d5138820   WORKING
            RAM[572] = 8'h24;
            RAM[573] = 8'h48;
            RAM[574] = 8'hE8;
            RAM[575] = 8'h00;
        // OR $10 $1 $3         $10 = defefffe  WORKING
            RAM[576] = 8'h25;
            RAM[577] = 8'h50;
            RAM[578] = 8'h23;
            RAM[579] = 8'h00;
        // XOR $11 $6 $7        $11 = ffffc40a  WORKING
            RAM[580] = 8'h26;
            RAM[581] = 8'h58;
            RAM[582] = 8'hC7;
            RAM[583] = 8'h00;
        //SLT $12 $11 $4        $12 = 1 since signed. $11 is very negative.     WORKING
            RAM[584] = 8'h2A;
            RAM[585] = 8'h60;
            RAM[586] = 8'h64;
            RAM[587] = 8'h01;
        //SLTU $13 $11 $4       $12 = 0 since unsigned. $11 is very positive.   WORKING
            RAM[588] = 8'h2B;
            RAM[589] = 8'h68;
            RAM[590] = 8'h64;
            RAM[591] = 8'h01;
        //BEQ $13 $14 0x7       Jump to 220 but still do the ADDI after. Then move onto the ADDIU  WORKING
            RAM[592] = 8'h06;
            RAM[593] = 8'h00;
            RAM[594] = 8'hAE;
            RAM[595] = 8'h11;
        //ADDIU $13 $6 0x50     $13 = 2ede      WORKING
            RAM[596] = 8'h32;
            RAM[597] = 8'h00;
            RAM[598] = 8'hCD;
            RAM[599] = 8'h24;
        //ANDI $14 $7 0x214     $14 = 203       WORKING
            RAM[620] = 8'h14;
            RAM[621] = 8'h02;
            RAM[622] = 8'hEE;
            RAM[623] = 8'h30;
        //BGTZ $7 0x3           Should not jump to 240 as signed of $7 is less than 0.  WORKING?
            RAM[624] = 8'h03;
            RAM[625] = 8'h00;
            RAM[626] = 8'hE0;
            RAM[627] = 8'h1C;
        //BGTZ $4 0x5           Should jump to 252 as signed of $4 is greater than 0. Will do 232 first.    WORKING
            RAM[628] = 8'h05;
            RAM[629] = 8'h00;
            RAM[630] = 8'h80;
            RAM[631] = 8'h1C;
        //ORI $15 $5 0x1249     $15 = a92f9     WORKING 
            RAM[632] = 8'h29;
            RAM[633] = 8'h14;
            RAM[634] = 8'hAF;
            RAM[635] = 8'h34;
        //XORI $16 $5 0x1249    $16 = a80b1     WORKING
            RAM[652] = 8'h49;
            RAM[653] = 8'h12;
            RAM[654] = 8'hB0;
            RAM[655] = 8'h38;
        //  

        //SW $4, 8, $0
        /*(RAM[104] = 8'h08;
        RAM[105] = 8'h00;
        RAM[106] = 8'h01;
        RAM[107] = 8'hAC;*/
        //SB $4, 8, $0
        //RAM[104] = 8'h08;
        //RAM[105] = 8'h00;
        //RAM[106] = 8'h01;
        //RAM[107] = 8'hA4;
    end

    initial begin
        clk=0;
        repeat (300) begin
            #1;
            clk=!clk;
        end
        $finish(0);
    end

    initial begin
        waitrequest=0;
        reset=0;
        repeat (20) begin
            #2;
            //  Displays
                $display("1\tAddress %d", address - 3217031068);
                //$display("Combined Output of CPU: %d", {r1, r2, r3, r4});
                //$display("%d %h",8, RAM[8]);
                //$display("%d %h",9, RAM[9]);
                //$display("%d %h",10, RAM[10]);
                //$display("%d %h",11, RAM[11]);
                //if (write) begin
                //    $display("Writing at location: %d with data %h with byteenable %b", address, writedata, byteenable);
                //end
        end
        repeat (2) begin
            reset = 1;
            $display("2\tAddress %d", address - 3217031068);
            #2;
        end
        repeat(30) begin
            reset = 0;
            $display("3\tAddress %d", address - 3217031068);
            #2;
        end
    end

    always_ff @(posedge clk) begin
        if (read) begin
            r4 = (address > 3217031167) ? (RAM[address - 3217031068]) :     (RAM[address]) * (byteenable[0]);
            r3 = (address > 3217031167) ? (RAM[address + 1 - 3217031068]) : (RAM[address + 1]) * (byteenable[1]);
            r2 = (address > 3217031167) ? (RAM[address + 2 - 3217031068]) : (RAM[address + 2]) * (byteenable[2]);
            r1 = (address > 3217031167) ? (RAM[address + 3 - 3217031068]) : (RAM[address + 3]) * (byteenable[3]);
            readdata = {r1, r2, r3, r4};
        end
        if (write) begin
            RAM[address + 3] <= writedata[31:24] * byteenable[3];
            RAM[address + 2] <= writedata[23:16] * byteenable[2];
            RAM[address + 1] <= writedata[15:8] * byteenable[1];
            RAM[address] <= writedata[7:0] * byteenable[0];
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