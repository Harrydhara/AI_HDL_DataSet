/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_tqv_jesari_CAN (
    input  wire       clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input  wire       rst_n,        // Reset_n - low to reset.

    input  wire [7:0] ui_in,        // The input PMOD, always available.  Note that ui_in[7] is 
                                    // normally used for UART RX.
                                    // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output wire [7:0] uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                    // Note that uo_out[0] is normally used for UART TX.

    input  wire [5:0] address,      // Address within this peripheral's address space
    input  wire [31:0] data_in,     // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input  wire [1:0] data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input  wire [1:0] data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits

    output wire [31:0] data_out,    // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output wire        data_ready,

    output wire        user_interrupt  // Dedicated interrupt request for this peripheral
);
    // changing the bus interface to LaRVa's...

	// Chip select: only 32-bit wide reads & writes allowed
	wire cs = (data_write_n==2'b10) | (data_read_n==2'b10);
	// write lanes
	wire [3:0]bsel = (data_write_n==2'b10) ? 4'b1111 : 4'b0000;

	// peripheral instance
	wire irqrx, irqrxerr, irqtx, can_tx, can_rx;
    
	CAN CAN0 (
		.clk(clk), .reset(~rst_n),
		.cs(cs), 
		.rs(address[3:2]),
		.bytesel(bsel),
		.d(data_in),
		.q(data_out),
		.irqrx(irqrx),
		.irqrxerr(irqrxerr),
		.irqtx(irqtx),
		.can_tx(can_tx),
		.can_rx(can_rx)
	);
	assign user_interrupt = irqrx | irqrxerr | irqtx;
	assign can_rx = ui_in[1];
    assign uo_out[1] = can_tx;
	assign data_ready = 1'b1;
	
    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.
    wire _unused = &{ui_in[0], ui_in[7:2], address[5:4], address[1:0], 1'b0};
	assign uo_out[7:2]=6'b0;
	assign uo_out[0]=1'b0;
endmodule


///////////////////////////////////////////////////////////////////////////////
//                  simplified CAN bus controller                            //
//                       Jesús Arias (2022)                                  //
//                                                                           //
// Public Domain code (bugs included).                                       //
///////////////////////////////////////////////////////////////////////////////


module CAN (
	input  wire        clk,		// Main clock input
	input  wire        reset,		// async reset

	// Core interface
	input  wire        cs,				// Peripheral chip select
	input  wire [1:0]  rs,		// Register select
	input  wire [3:0]  bytesel,	// Byte select for writes
	output wire [31:0] q,		// output bus
	input  wire [31:0] d,		// input bus

	// IRQs
	output wire        irqrx,			// Valid frame received
	output wire        irqrxerr,		// received errors
	output wire        irqtx,  		// Ready to transmit

	// CAN lines
	input  wire        can_rx,			// receiver input
	output wire        can_tx			// Transmitter output

);
    // --------------------------------------------------------
    // Parameter Definitions
    // --------------------------------------------------------
    parameter IDLE		= 3'b000;
    parameter IDSTD		= 3'b001;
    parameter IDEXT		= 3'b010;
    parameter DLC 		= 3'b011;
    parameter DATA		= 3'b100;
    parameter CRC		= 3'b101;
    parameter ACK		= 3'b110;
    parameter ERR		= 3'b111;

    parameter TXIDLE	= 3'b000;	// Nothing to transmit
    parameter TXWAIT	= 3'b001;	// Waiting for CTS
    parameter TXSTART	= 3'b010;   // Start bit
    parameter TXID		= 3'b011;	// Shifting ID+RTR (arbitration)
    parameter TXDLC 	= 3'b100;	// Shifting DLC
    parameter TXDATA	= 3'b101;   // Shifting data
    parameter TXCRC		= 3'b110;	// Shifting CRC
    parameter TXEOF		= 3'b111;	// Trailing recessive bits & ACK detection

    // --------------------------------------------------------
    // Hoisted Declarations (Fix for default_nettype none)
    // --------------------------------------------------------
    
    // System interface signals
    wire csid, csdlcf, csdata0, csdata1;
    
    // BAUD reg
    reg [9:0] bauddiv;
    reg [2:0] irqen;

    // Receiver Signals
    reg [1:0] rrxd;
    wire resinc;
    reg [9:0] divrx;
    wire sample;
    wire clki0;
    reg [4:0] lastbits;
    wire stuffbit, errorfrm, passive;
    reg [20:0] sh;
    reg [2:0] st;
    wire btc; // defined with bittc
    
    // Flags
    reg crcerr, stufferr, frmav, ovwr;
    reg [14:0] crcr;
    wire badcrc;
    reg ackb;
    
    // Bit/Byte Counters (RX)
    reg [5:0] bitcnt;
    wire bittc;
    reg [2:0] bytecnt;
    wire [5:0] nbits;
    
    // RX Registers
    reg [28:0] rx_id;
    reg rtr;
    reg ext;
    reg [3:0] dlc;
    reg [7:0] rdata [0:7];

    // Transmitter Signals
    reg [2:0] txst;
    wire txing;
    reg [3:0] ctscnt;
    wire cts;
    reg [9:0] divtx;
    wire clk0tx;
    wire txsample;
    
    // TX Registers
    reg txrtr;
    reg txext;
    reg [31:0] txid;
    reg [5:0] txdlc;
    reg [3:0] txdlccopy;
    reg [31:0] txdata0;
    reg [31:0] txdata1;
    reg [14:0] txcrc;
    
    // TX Control
    wire txstrobe;
    wire txend;
    reg rts;
    wire biterr;
    wire txselout;
    reg [4:0] otx;
    wire txout;
    wire txstuff;
    
    // TX Counters
    reg [5:0] txbitcnt;
    wire txbittc;
    wire [5:0] txnbit;
    
    // TX Flags
    reg lostf;
    reg bitf;
    reg ackf;

    // --------------------------------------------------------
    // Implementation
    // --------------------------------------------------------

    //////////////// System interface //////////////
    assign csid   = cs & (~rs[1]) & (~rs[0]);
    assign csdlcf = cs & (~rs[1]) & ( rs[0]);
    assign csdata0= cs & ( rs[1]) & (~rs[0]);
    assign csdata1= cs & ( rs[1]) & ( rs[0]);

    // output register mapping
    assign q =
        (csid    ? {ext,rtr,1'b0,rx_id} : 32'b0) |
        (csdlcf  ? {irqen,3'h0,bauddiv,4'h0,ackf,bitf,lostf,rts,ovwr,frmav,crcerr,stufferr,dlc} : 32'b0) |
        (csdata0 ? {rdata[3],rdata[2],rdata[1],rdata[0]} : 32'b0) |
        (csdata1 ? {rdata[7],rdata[6],rdata[5],rdata[4]} : 32'b0);
        
    assign irqrx=irqen[0]& frmav;
    assign irqrxerr=irqen[1]&(stufferr|crcerr);
    assign irqtx=irqen[2]&(~rts);
	
    //////////////// BAUD reg ////////////////
    always @(posedge clk or posedge reset)
        if (reset) begin
            bauddiv <= 10'b0;
            irqen   <= 3'b0;
        end else if (csdlcf & bytesel[3] & bytesel[2]) begin
            bauddiv <= d[25:16];
            irqen   <= d[31:29];
        end

    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    //                      CAN RECEIVER
    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////

    /// clock sync
    always @(posedge clk or posedge reset) 
        if (reset) rrxd<= 2'b11;
        else rrxd<={rrxd[0],can_rx|txing};
        
    assign resinc = rrxd[0]^rrxd[1];	// change at the input if 1

    // Clock divider
    assign sample= (divrx==({1'b0,bauddiv[9:1]})); // Sampling pulse (at half bit time)
    assign clki0 = (divrx==0); // Bit end (full bit time)
    
    always @ (posedge clk or posedge reset)
        if (reset) divrx <= 10'b0;
        else divrx <= (resinc|clki0) ? bauddiv : divrx-1;

    // Bit destuffing
    always @ (posedge clk) if (sample) lastbits <= {lastbits[3:0],rrxd[0]};
    assign stuffbit = (lastbits==5'h0) || (lastbits==5'h1f);
    assign errorfrm = (lastbits==5'h0)&(~rrxd[0]);
    assign passive = (lastbits==5'h1f)&rrxd[0];

    // Input sample reg
    // Note: delay required due to t_hold simulation issues
    always @ (posedge clk) if (sample&(~stuffbit)) sh <= {sh[19:0],rrxd[0]};
    
    // State machine
    assign btc=(~stuffbit)&bittc;

    always @(posedge clk or posedge reset)
    if (reset) st<=IDLE; else
    begin
      if (sample)
         case (st)
            IDLE:   if (~rrxd[0]) st<=IDSTD;
            IDSTD:	st<=errorfrm ? ERR : (passive ? IDLE : (btc ? (sh[1]? IDEXT : DLC) : IDSTD));
            IDEXT:	st<=errorfrm ? ERR : (passive ? IDLE : (btc ? DLC:IDEXT));
            DLC:	st<=errorfrm ? ERR : (passive ? IDLE : (btc ? (((sh[3:0]!=4'b0)&(~rtr)) ? DATA : CRC):DLC));
            DATA:	st<=errorfrm ? ERR : (passive ? IDLE : (btc ? CRC:DATA));
            CRC:	st<=errorfrm ? ERR : (passive ? IDLE : (btc ? ((~badcrc)?ACK:IDLE):CRC));
            ACK:	if (bittc) st<=IDLE;
            ERR:	if (rrxd[0]) st<=IDLE;
            endcase
    end

    assign nbits=
        ((st==IDLE) ? 6'd15 : 6'b0) |
        ((st==IDSTD) ? (sh[1] ? 6'd20 : 6'd4) : 6'b0) |
        ((st==IDEXT) ? 6'd4 : 6'b0) |
        ((st==DLC) ? (((sh[3:0]!=4'b0)&(~rtr)) ? {sh[2:0],3'b000} : 6'd15) : 6'b0) |
        ((st==DATA) ? 6'd15 : 6'b0) |
        ((st==CRC) ? 6'd3 : 6'b0);

    // Bit counter
    assign bittc=(bitcnt==1);

    always @ (posedge clk) 
        if (st==IDLE) bitcnt<=nbits;
        else if (sample&((~stuffbit)|(st==ACK)))
            if (bittc) bitcnt<=nbits;
            else bitcnt<=bitcnt-1;

    // Byte counter
    always @ (posedge clk)
        if (sample&((~stuffbit))) bytecnt <= (st!=DATA) ?
            3'b0 : ((bitcnt[2:0]==3'b1) ? bytecnt+1 : bytecnt);
        
    // BIT ACK
    always @ (posedge clk or posedge reset)
      if (reset) ackb <= 1'b0; else
        if (st!=ACK) ackb <= 1'b1;
        else if (clki0) ackb <= ~(bitcnt[0]&bitcnt[1]);

    // Regs
    always @ (posedge clk) begin
        if (sample&(~stuffbit)&bittc&(st==IDSTD)) rx_id<={18'h0,sh[13:3]};
        if (sample&(~stuffbit)&bittc&(st==IDEXT)) rx_id<={rx_id[10:0],sh[20:3]};
    end
    always @ (posedge clk) begin
        if (sample&(~stuffbit)&bittc&(st==IDSTD)) rtr<=sh[2];
        if (sample&(~stuffbit)&bittc&(st==IDEXT)) rtr<=sh[2];
    end
    always @ (posedge clk) 
        if (sample&(~stuffbit)&bittc&(st==IDSTD)) ext<=sh[1];

    always @ (posedge clk) 
        if (sample&(~stuffbit)&bittc&(st==DLC)) dlc<=sh[3:0];

    always @ (posedge clk) 
        if (sample&(~stuffbit)&(st==DATA)&(bitcnt[2:0]==1)) rdata[bytecnt]<=sh[7:0];

    // CRC
    always @ (posedge clk)
        if (st==IDLE) crcr <= 15'b0;
        else if (sample&(~stuffbit))
            crcr <= {crcr[13:0],1'b0}^((crcr[14]^rrxd[0]) ? 15'h4599 : 15'b0);
    // Flags
    assign badcrc = (crcr!=15'b0);

    always @ (posedge clk or posedge reset)
      if (reset) {crcerr,stufferr,frmav,ovwr} <= 4'b0;
      else
        // Reading ID reg clears these flags
        if (csid&(bytesel==4'b0000)) begin frmav<=1'b0; ovwr<=1'b0; crcerr<=1'b0; stufferr<=1'b0; end
        else begin
            if (sample&(~stuffbit)&bittc&(st==CRC)) frmav<=~badcrc;
            if (sample&(~stuffbit)&bittc&(st==CRC)) crcerr<=badcrc;
            if (sample&(~stuffbit)&bittc&(st==IDSTD)) ovwr<=frmav;
            if ((st==IDSTD)&(bitcnt==15)) stufferr<=1'b0;
            else if (sample&(st>IDLE)&(st<ACK)&(errorfrm|passive)) stufferr<=~txing;
        end


    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    //                      CAN TRANSMITTER
    /////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    // Clear to Send timer (11 recessive bits before TX)
    assign cts = (ctscnt==10);
    
    always @(posedge clk or posedge reset)
        if (reset) ctscnt <= 4'b0; else
            if (~can_rx) ctscnt <= 4'b0;
            else if ((~cts)&clki0) ctscnt <= ctscnt+1;
    // TX clock
    assign clk0tx=(divtx==0);	// reload pulse
    assign txsample=(divtx=={1'b0,bauddiv[9:1]});
    
    always @ (posedge clk or posedge reset)
      if (reset) divtx <= 10'b0; else
        divtx <= ((txst==TXWAIT)&(~cts)&(~can_rx)) ?
            10'b0 : ((clk0tx) ? bauddiv : divtx-1);

    // registers
    // ID shift reg
    always @(posedge clk) begin
        if (csid & (bytesel==4'b1111)) begin
            txext<=d[31];
            txrtr<=d[30];
            txid<=d[31]? {d[28:18],2'b11,d[17:0],d[30]} : {d[10:0],d[30],20'h0};
        end
        else if(clk0tx & (~txstuff)&(txst==TXID)) txid<={txid[30:0],1'b0};
    end

    // DLC shift rreg
    always @(posedge clk) begin
        if (csdlcf  & bytesel[0]) txdlc<={2'b00,d[3:0]};
        else if(clk0tx & (~txstuff)&(txst==TXDLC)) txdlc<={txdlc[4:0],1'b0};
    end
    always @(posedge clk) if (csdlcf  & bytesel[0]) txdlccopy<=d[3:0];

    // DATA shift rreg
    always @(posedge clk) begin
        if(clk0tx & (~txstuff)&(txst==TXDATA))
            {txdata0,txdata1}<={txdata0[30:0],txdata1,1'b0};
        else begin
            // Endian conversion on data regs
            if (csdata0 & bytesel[3]) txdata0[ 7: 0]<=d[31:24];
            if (csdata0 & bytesel[2]) txdata0[15: 8]<=d[23:16];
            if (csdata0 & bytesel[1]) txdata0[23:16]<=d[15: 8];
            if (csdata0 & bytesel[0]) txdata0[31:24]<=d[ 7: 0];
            if (csdata1 & bytesel[3]) txdata1[ 7: 0]<=d[31:24];
            if (csdata1 & bytesel[2]) txdata1[15: 8]<=d[23:16];
            if (csdata1 & bytesel[1]) txdata1[23:16]<=d[15: 8];
            if (csdata1 & bytesel[0]) txdata1[31:24]<=d[ 7: 0];
        end
    end

    // CRC
    always @ (posedge clk)
        if (txst==TXSTART) txcrc <= 15'b0;
        else if (clk0tx & (~txstuff))
            txcrc <= ({txcrc[13:0],1'b0}^(((txcrc[14]^txselout)&(txst!=TXCRC)) ? 15'h4599 : 15'b0));
            
    //// RTS flag (request tio send)
    assign txstrobe = csdlcf & bytesel[1] & d[8]; 
    assign txend = (txst==TXIDLE);
    
    always @(posedge clk or posedge reset)
      if (reset) rts <= 1'b0; else rts <= txstrobe ?
        1'b1 : (txend ? 1'b0 : rts);

    // Bit error monitor (for arbitration)
    assign biterr = (can_tx^can_rx);

    assign txing = (txst>TXID)&(txst<TXEOF);	// Transmitting: mute RX after ID

    // Data selection
    assign txselout=	((txst==TXID) ? txid[31]     : 1'b1 ) &
                    ((txst==TXDLC)? txdlc[5]     : 1'b1 ) &
                    ((txst==TXDATA)? txdata0[31] : 1'b1 ) &
                    ((txst==TXCRC)? txcrc[14]    : 1'b1 ) &
                    ((txst==TXSTART)? 1'b0       : 1'b1 ) ;
    // Bit stuffing
    always @(posedge clk) if (clk0tx) otx <= {otx[3:0],txout};
    assign txstuff = ((otx==5'b0)|(otx==5'b11111))&(txst>TXSTART)&(txst<TXEOF);
    assign txout=txstuff ? (~otx[0]):txselout;

    ////// Bit counter //////
    // values for counter reload
    assign txnbit=
        ((txst==TXWAIT) ? 6'd1 : 6'b0) |
        ((txst==TXSTART) ? (txext ? 6'd32 : 6'd12) : 6'b0) |
        ((txst==TXID) ? 6'd6 : 6'b0) |
        ((txst==TXDLC) ? (((txdlccopy==4'b0)|(txrtr)) ? 6'd15 : {txdlccopy[2:0],3'b000}) : 6'b0) |
        ((txst==TXDATA) ? 6'd15 : 6'b0) |
        ((txst==TXCRC) ? 6'd11 : 6'b0);
        
    assign txbittc =(txbitcnt==1);
    
    always @(posedge clk) 
        if (txst==TXWAIT) txbitcnt <= 6'd1;
        else if (clk0tx & (~txstuff)) txbitcnt <= (txbittc ? txnbit : txbitcnt-1);
        
    ////// State machine //////
    always @(posedge clk or posedge reset)
    if (reset) txst <= TXIDLE; else 
    begin
        case (txst)
        TXIDLE:		if (txstrobe) txst<=TXWAIT;
        TXWAIT:		if (clk0tx & cts) txst<=TXSTART;
        TXSTART:	if (clk0tx) txst<=TXID;
        TXID:		if (biterr&txsample) txst<=TXIDLE; else if(txbittc&clk0tx) txst<=TXDLC;
        TXDLC:		if (biterr&txsample) txst<=TXIDLE; else if(txbittc&clk0tx) txst<=((txdlccopy==4'b0)|(txrtr))?TXCRC:TXDATA;
        TXDATA:		if (biterr&txsample) txst<=TXIDLE; else if(txbittc&clk0tx) txst<=TXCRC;
        TXCRC:		if (biterr&txsample) txst<=TXIDLE; else if(txbittc&clk0tx) txst<=TXEOF;
        TXEOF:		if (txbittc&clk0tx) txst<=TXIDLE;
        endcase
    end

    ////// TX flags //////
    // Arbitration Lost flag
    always @(posedge clk)
        if (txst==TXSTART) lostf <= 1'b0;
        else if ((txst==TXID)&biterr&txsample) lostf <= 1'b1;

    // Bit error flag
    always @(posedge clk)
        if (txst==TXSTART) bitf <= 1'b0;
        else if ((txst>TXID)&(txst<TXEOF)&biterr&txsample) bitf <= 1'b1;
    // ACK received flag
    always @(posedge clk)
        if ((txst==TXEOF)&(txbitcnt==10)&txsample) ackf <= ~can_rx;

    // CAN Output
    assign can_tx = ackb & txout;

endmodule